// 渲染公共 header
function renderHeader(activeNav) {
  const cats = ['电影', '连续剧', '综艺', '动漫'];
  const navLinks = cats.map(function(c) {
    const active = c === activeNav ? ' class="active"' : '';
    return '<a' + active + ' href="/category?type=' + encodeURIComponent(c) + '">' + c + '</a>';
  }).join('');

  document.getElementById('header').innerHTML =
    '<div class="logo"><a href="/">🎬 影视</a></div>'
    + '<nav>' + navLinks + '</nav>'
    + '<div class="search-box">'
    + '<input id="searchInput" type="text" placeholder="搜索..." onkeydown="if(event.key===\'Enter\')doSearch()">'
    + '<button onclick="doSearch()">搜</button>'
    + '</div>';
}

function doSearch() {
  var q = document.getElementById('searchInput').value.trim();
  if (q) window.location.href = '/search?q=' + encodeURIComponent(q);
}

// 卡片 HTML
function cardHTML(item) {
  var id = (item.url.match(/\/id\/(\d+)/) || [])[1];
  var imgEl = item.img
    ? '<div class="card-img-wrap"><img src="' + item.img + '" loading="lazy" onerror="this.parentElement.innerHTML=\'<span>🎬</span>\'"><div class="card-overlay">'
      + '<div class="card-overlay-top">'
      + (item.score ? '<span class="card-score">' + item.score + '</span>' : '')
      + (item.quality ? '<span class="card-quality">' + item.quality + '</span>' : '')
      + '</div>'
      + (item.hot ? '<div class="card-overlay-bottom"><span class="card-hot-badge">🔥 ' + formatHot(item.hot) + '</span></div>' : '')
      + '</div></div>'
    : '<div class="card-img-wrap"><span>🎬</span></div>';

  var meta = '';
  if (item.status || id) {
    var watched = '';
    if (id) {
      try {
        var lastTitle = localStorage.getItem('lastep_' + id + '_title');
        if (lastTitle) {
          if (lastTitle.indexOf('__time__') === 0) {
            // 电影：显示时间进度
            watched = '看到 ' + formatTimeShort(parseInt(lastTitle.replace('__time__', '')));
          } else {
            watched = '看到 ' + lastTitle;
          }
        }
      } catch(e) {}
    }
    var statusHtml = '';
    if (item.status && watched) {
      statusHtml = '<div class="card-status">'
        + '<span>' + item.status + '</span>'
        + '<span class="card-watched">' + watched + '</span>'
        + '</div>';
    } else if (item.status) {
      statusHtml = '<div class="card-status">' + item.status + '</div>';
    } else if (watched) {
      statusHtml = '<div class="card-status"><span class="card-watched">' + watched + '</span></div>';
    }
    meta += statusHtml;
  }
  if (item.actors) meta += '<div class="card-actors">' + item.actors.split(/\s+/).slice(0, 3).join(' · ') + '</div>';

  return '<a class="card" href="/detail?id=' + id + '">'
    + imgEl
    + '<div class="card-info"><div class="card-title">' + item.title + '</div>'
    + meta
    + '</div></a>';
}

function formatHot(n) {
  n = parseInt(n) || 0;
  if (n >= 10000) return (n / 10000).toFixed(1) + '万';
  return n.toString();
}

// 分页 HTML
function paginationHTML(current, total, baseUrl) {
  var totalPages = total ? Math.ceil(total / 24) : null;
  var html = '<div class="pagination">';
  if (current > 1) html += '<a class="pg-btn" href="' + baseUrl + '&page=' + (current - 1) + '">上一页</a>';
  html += '<span class="pg-btn active">' + current + '</span>';
  if (!totalPages || current < totalPages) html += '<a class="pg-btn" href="' + baseUrl + '&page=' + (current + 1) + '">下一页</a>';
  html += '</div>';
  return html;
}

function formatTimeShort(s) {
  s = Math.floor(s);
  var h = Math.floor(s / 3600);
  var m = Math.floor((s % 3600) / 60);
  var sec = s % 60;
  var pad = function(n) { return n < 10 ? '0' + n : '' + n; };
  if (h > 0) return h + ':' + pad(m) + ':' + pad(sec);
  return pad(m) + ':' + pad(sec);
}
