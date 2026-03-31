const express = require('express');
const axios = require('axios');
const cheerio = require('cheerio');

const app = express();
const BASE = 'https://www.olehdtv.com';

const AD_DOMAINS = ['202807.net', 'u68web7.ca', 'cc88.win', 'rbvisb.com', 'dx55.com', 'mk730.com', '0597b5.com', 'blm8.app', '225.52.94'];

function isAd(url) {
  if (!url) return true;
  return AD_DOMAINS.some(d => url.includes(d));
}

async function fetchPage(url) {
  const res = await axios.get(url, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml',
      'Accept-Language': 'zh-CN,zh;q=0.9',
      'Referer': BASE
    },
    timeout: 12000
  });
  return res.data;
}

function dedup(items) {
  const seen = new Set();
  return items.filter(i => {
    if (seen.has(i.url)) return false;
    seen.add(i.url);
    return true;
  });
}

app.use(express.static('public'));

// 页面路由
app.get('/category', (req, res) => res.sendFile('category.html', { root: 'public' }));
app.get('/detail',   (req, res) => res.sendFile('detail.html',   { root: 'public' }));
app.get('/search',   (req, res) => res.sendFile('search.html',   { root: 'public' }));

// 首页
app.get('/api/home', async (req, res) => {
  try {
    const html = await fetchPage(BASE);
    const $ = cheerio.load(html);
    const sections = {};
    const allowed = ['\u7535\u5f71', '\u8fde\u7eed\u5267', '\u7efc\u827a', '\u52a8\u6f2b'];

    $('h2').each((_, el) => {
      const rawTitle = $(el).text().trim();
      // h2 text may have icon chars before the title
      const title = allowed.find(t => rawTitle.includes(t));
      if (!title) return;

      // 结构: div.pannel > div.pannel_head > h2
      //        div.pannel > div.cbox_list li.vodlist_item
      const pannel = $(el).closest('.pannel');
      const items = [];

      pannel.find('li.vodlist_item').each((_, li) => {
        const a = $(li).find('a.vodlist_thumb').first();
        const href = a.attr('href') || '';
        const t = a.attr('title') || '';
        const img = a.attr('data-original') || a.attr('data-src') || '';
        const rawScore = a.find('span.text_right').text().trim();
        const scoreMatch = rawScore.match(/^[\d.]+/);
        const score = scoreMatch ? scoreMatch[0] : '';
        const status = rawScore.replace(/^[\d.]+/, '').trim();
        const hot = a.find('span:last-child').text().replace(/\s/g, '').replace(/[^\d]/g, '');
        const quality = a.find('em.voddate_year').last().text().trim();
        const actors = $(li).find('.vodlist_sub').text().trim().replace(/\s+/g, ' ');
        if (!href.includes('/vod/detail/') || isAd(href) || !t) return;
        items.push({ title: t, url: href, img, score, status, hot, quality, actors });
      });

      sections[title] = dedup(items).slice(0, 12);
    });

    res.json(sections);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// 分类列表
app.get('/api/list', async (req, res) => {
  const { type, page = 1 } = req.query;
  const typeMap = { '\u7535\u5f71': 1, '\u8fde\u7eed\u5267': 2, '\u7efc\u827a': 3, '\u52a8\u6f2b': 4 };
  const id = typeMap[type];
  if (!id) return res.status(400).json({ error: 'unknown type' });

  try {
    const url = `${BASE}/index.php/vod/type/id/${id}/page/${page}.html`;
    const html = await fetchPage(url);
    const $ = cheerio.load(html);
    const items = [];

    $('li.vodlist_item').each((_, li) => {
      const a = $(li).find('a.vodlist_thumb').first();
      const href = a.attr('href') || '';
      const title = a.attr('title') || '';
      const img = a.attr('data-original') || a.attr('data-src') || '';
      // 评分和更新状态混在同一个 span，用正则拆开
      const rawScore = a.find('span.text_right').text().trim();
      const scoreMatch = rawScore.match(/^[\d.]+/);
      const score = scoreMatch ? scoreMatch[0] : '';
      const status = rawScore.replace(/^[\d.]+/, '').trim();
      // 热度：左下角播放量
      const hot = a.find('span:last-child').text().replace(/\s/g, '').replace(/[^\d]/g, '');
      // 清晰度
      const quality = a.find('em.voddate_year').last().text().trim();
      // 演员
      const actors = $(li).find('.vodlist_sub').text().trim().replace(/\s+/g, ' ');
      if (!href.includes('/vod/detail/') || isAd(href) || !title) return;
      items.push({ title, url: href, img, score, status, hot, quality, actors });
    });

    const totalMatch = $('body').text().match(/\u5171(\d+)\u6761/);
    const total = totalMatch ? parseInt(totalMatch[1]) : null;

    res.json({ items: dedup(items), page: parseInt(page), total });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// 详情页
app.get('/api/detail', async (req, res) => {
  const { id } = req.query;
  if (!id) return res.status(400).json({ error: 'missing id' });

  try {
    const url = `${BASE}/index.php/vod/detail/id/${id}.html`;
    const html = await fetchPage(url);
    const $ = cheerio.load(html);

    const title = $('title').text().split('_')[0].trim();
    // 封面：detail页的vodlist_thumb的data-original
    const coverA = $('a.vodlist_thumb').first();
    const cover = coverA.attr('data-original') || coverA.find('img').attr('src') || '';
    const desc = $('.content_desc span').first().text().trim();
    const score = $('.star_tips').first().text().trim();

    const episodes = [];
    // 先找"立即播放"按钮（电影通常只有这一个入口）
    $('a[href*="/vod/play/id/"]').each((_, a) => {
      const href = $(a).attr('href') || '';
      const epTitle = $(a).text().trim().replace(/\s+/g, '');
      if (!href || href.includes('play_vip') || href.includes('javascript')) return;
      // 保留所有非空标题的链接，包括"立即播放"
      if (!epTitle) return;
      // 把"立即播放"统一改为"播放"
      const displayTitle = (epTitle.includes('\u7acb\u5373\u64ad\u653e') || epTitle.includes('\u64ad\u653e'))
        ? '\u64ad\u653e'
        : epTitle;
      episodes.push({ title: displayTitle, url: href });
    });

    res.json({ title, cover, desc, score, episodes: dedup(episodes) });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// 提取视频源 m3u8
app.get('/api/video-src', async (req, res) => {
  const { path: playPath } = req.query;
  if (!playPath) return res.status(400).json({ error: 'missing path' });
  try {
    const url = BASE + playPath;
    const html = await fetchPage(url);
    const match = html.match(/player_aaaa=(\{[^<]+\})/);
    if (!match) return res.status(404).json({ error: 'no player data found' });
    const data = JSON.parse(match[1]);
    const src = data.url ? data.url.replace(/\\\//g, '/') : null;
    if (!src) return res.status(404).json({ error: 'no url in player data' });
    res.json({ src });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// 搜索
app.get('/api/search', async (req, res) => {
  const { q, page = 1 } = req.query;
  if (!q) return res.status(400).json({ error: 'missing q' });

  try {
    const url = `${BASE}/index.php/vod/search/page/${page}/wd/${encodeURIComponent(q)}.html`;
    const html = await fetchPage(url);
    const $ = cheerio.load(html);
    const items = [];

    $('li.searchlist_item').each((_, li) => {
      const a = $(li).find('a.vodlist_thumb').first();
      const href = a.attr('href') || '';
      const title = a.attr('title') || '';
      const img = a.attr('data-original') || a.attr('data-src') || '';
      const rawScore = a.find('span.text_right').text().trim();
      const scoreMatch = rawScore.match(/^[\d.]+/);
      const score = scoreMatch ? scoreMatch[0] : '';
      const status = rawScore.replace(/^[\d.]+/, '').trim()
        || a.find('.pic_text').text().trim();
      const actors = $(li).find('.vodlist_sub').first().text().trim().replace(/\s+/g, ' ');
      if (!href.includes('/vod/detail/') || isAd(href) || !title) return;
      items.push({ title, url: href, img, score, status, actors });
    });

    // fallback
    if (items.length === 0) {
      $('a.vodlist_thumb[href*="/vod/detail/"]').each((_, a) => {
        const href = $(a).attr('href') || '';
        const title = $(a).attr('title') || '';
        const img = $(a).attr('data-original') || '';
        if (isAd(href) || !title) return;
        items.push({ title, url: href, img, score: '', status: '', actors: '' });
      });
    }

    res.json({ items: dedup(items), page: parseInt(page) });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => console.log('running on http://localhost:' + PORT + ' (LAN: http://192.168.89.149:' + PORT + ')'));
