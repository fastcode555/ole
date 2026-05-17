// 渲染公共 header
function renderHeader(activeNav) {
  var cats = ['电影', '连续剧', '综艺', '动漫'];
  var navLinks = cats.map(function(c) {
    var active = c === activeNav ? ' class="active"' : '';
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
  var favs = [];
  try { favs = JSON.parse(localStorage.getItem('favorites')) || []; } catch(e) {}
  var faved = id && favs.indexOf(id) !== -1;

  var imgEl = item.img
    ? '<div class="card-img-wrap"><img src="' + item.img + '" loading="lazy" onerror="this.parentElement.innerHTML=\'<span>🎬</span>\'">'
      + '<div class="card-overlay">'
      + '<div class="card-overlay-top">'
      + (item.score ? '<span class="card-score">' + item.score + '</span>' : '')
      + (item.quality ? '<span class="card-quality">' + item.quality + '</span>' : '')
      + '</div>'
      + '<div class="card-overlay-bottom">'
      + (item.hot ? '<span class="card-hot-badge">🔥 ' + formatHot(item.hot) + '</span>' : '')
      + '<button class="card-fav-btn' + (faved ? ' faved' : '') + '" data-vid="' + id + '">' + (faved ? '❤️' : '🤍') + '</button>'
      + '</div>'
      + '</div>'
      + '</div>'
    : '<div class="card-img-wrap"><span>🎬</span></div>';

  var meta = '';
  if (item.status || id) {
    var watched = '';
    if (id) {
      try {
        var lastTitle = localStorage.getItem('lastep_' + id + '_title');
        if (lastTitle) {
          if (lastTitle.indexOf('__time__') === 0) {
            watched = '看到 ' + formatTimeShort(parseInt(lastTitle.replace('__time__', '')));
          } else {
            watched = '看到 ' + lastTitle;
          }
        }
      } catch(e) {}
    }
    var statusHtml = '';
    if (item.status && watched) {
      statusHtml = '<div class="card-status"><span>' + item.status + '</span><span class="card-watched">' + watched + '</span></div>';
    } else if (item.status) {
      statusHtml = '<div class="card-status">' + item.status + '</div>';
    } else if (watched) {
      statusHtml = '<div class="card-status"><span class="card-watched">' + watched + '</span></div>';
    }
    meta += statusHtml;
  }
  if (item.actors) meta += '<div class="card-actors">' + item.actors.split(/\s+/).slice(0, 3).join(' · ') + '</div>';

  // 用 data-href 存跳转地址，不用 onclick 或 <a>
  return '<div class="card' + (faved ? ' card-faved' : '') + '" data-href="/detail?id=' + id + '" data-faved="' + (faved ? '1' : '0') + '">'
    + imgEl
    + '<div class="card-info"><div class="card-title">' + item.title + '</div>'
    + meta
    + '</div></div>';
}

function formatHot(n) {
  n = parseInt(n) || 0;
  if (n >= 10000) return (n / 10000).toFixed(1) + '万';
  return n.toString();
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

// 收藏排序：收藏的提前，各组内保持原顺序
function sortByFav(gridEl) {
  if (!gridEl) return;
  var cards = Array.from(gridEl.querySelectorAll('.card'));
  var faved = cards.filter(function(c) { return c.dataset.faved === '1'; });
  var normal = cards.filter(function(c) { return c.dataset.faved !== '1'; });
  faved.concat(normal).forEach(function(c) { gridEl.appendChild(c); });
}

// 全局事件委托 —— 捕获阶段，最先执行
document.addEventListener('click', function(e) {
  // 先判断是否点了喜欢按钮（或其内部子元素）
  var favBtn = e.target.closest('.card-fav-btn');
  if (favBtn) {
    e.stopImmediatePropagation();
    e.preventDefault();
    var vid = favBtn.dataset.vid;
    if (!vid) return;
    var favs = [];
    try { favs = JSON.parse(localStorage.getItem('favorites')) || []; } catch(ex) {}
    var idx = favs.indexOf(vid);
    var nowFaved = idx === -1;
    if (nowFaved) favs.push(vid); else favs.splice(idx, 1);
    try { localStorage.setItem('favorites', JSON.stringify(favs)); } catch(ex) {}
    favBtn.textContent = nowFaved ? '❤️' : '🤍';
    favBtn.classList.toggle('faved', nowFaved);
    var card = favBtn.closest('.card');
    if (card) {
      card.classList.toggle('card-faved', nowFaved);
      card.dataset.faved = nowFaved ? '1' : '0';
      var badge = card.querySelector('.card-fav-badge');
      if (badge) badge.remove();
    }
    return;
  }

  // 点卡片其他区域跳转
  var card = e.target.closest('.card[data-href]');
  if (card) {
    window.location.href = card.dataset.href;
  }
}, true); // true = 捕获阶段，早于任何冒泡
