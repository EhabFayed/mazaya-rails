// Mazaya shared behaviour: WhatsApp wiring, menus, reveals, counters,
// lead forms (POST /leads with WhatsApp fallback), gated downloads,
// client-side filters (category page, product finder, guide library).
(function () {
  'use strict';

  var body = document.body;
  var LOCALE = document.documentElement.lang === 'en' ? 'en' : 'ar-EG';
  var WA_DISPLAY = body.getAttribute('data-whatsapp-display') || '+966 50 000 0000';
  var WA_HREF = body.getAttribute('data-whatsapp-href') || ('https://wa.me/' + WA_DISPLAY.replace(/[^0-9]/g, ''));
  window.MAZAYA_WA = { display: WA_DISPLAY, href: WA_HREF };

  document.querySelectorAll('[data-wa]').forEach(function (a) { a.href = WA_HREF; a.target = '_blank'; a.rel = 'noopener'; });
  document.querySelectorAll('[data-wa-display]:not(body)').forEach(function (el) { el.textContent = WA_DISPLAY; });

  // ---- LTR: flip the RTL arrow glyphs used in link text ----
  if (document.documentElement.dir === 'ltr') {
    var walker = document.createTreeWalker(body, NodeFilter.SHOW_TEXT);
    var nodes = []; while (walker.nextNode()) { if (walker.currentNode.nodeValue.indexOf('\u2190') > -1) nodes.push(walker.currentNode); }
    nodes.forEach(function (n) { n.nodeValue = n.nodeValue.replace(/\u2190/g, '\u2192'); });
  }

  // ---- mobile menu ----
  var menuBtn = document.querySelector('.menu-btn');
  var mobileNav = document.querySelector('.mobile-nav');
  if (menuBtn && mobileNav) {
    menuBtn.addEventListener('click', function () {
      var open = mobileNav.classList.toggle('open');
      menuBtn.setAttribute('aria-expanded', open ? 'true' : 'false');
      body.style.overflow = open ? 'hidden' : '';
    });
    mobileNav.addEventListener('click', function (e) {
      if (e.target.tagName === 'A') { mobileNav.classList.remove('open'); body.style.overflow = ''; }
    });
  }

  // ---- scroll reveals ----
  var reveals = document.querySelectorAll('[data-reveal]');
  reveals.forEach(function (el) {
    el.style.opacity = '0'; el.style.transform = 'translateY(28px)';
    el.style.transition = 'opacity .8s ease, transform .8s ease';
  });
  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (en) {
      if (en.isIntersecting) { en.target.style.opacity = '1'; en.target.style.transform = 'none'; io.unobserve(en.target); }
    });
  }, { threshold: 0.12 });
  reveals.forEach(function (el) { io.observe(el); });

  // ---- counters ----
  var cio = new IntersectionObserver(function (entries) {
    entries.forEach(function (en) {
      if (!en.isIntersecting) return;
      var el = en.target, target = +el.getAttribute('data-count'), t0 = performance.now();
      var tick = function (now) {
        var p = Math.min((now - t0) / 1600, 1), e = 1 - Math.pow(1 - p, 3);
        el.textContent = Math.round(target * e).toLocaleString(LOCALE);
        if (p < 1) requestAnimationFrame(tick);
      };
      requestAnimationFrame(tick);
      cio.unobserve(el);
    });
  }, { threshold: 0.5 });
  document.querySelectorAll('[data-count]').forEach(function (el) { cio.observe(el); });

  // ---- lead forms ----
  // <form data-lead-form data-kind="rfq|quote|partner|download|contact" data-source="page">
  // Fields named lead[...] are sent as-is; any other named field goes into lead[payload][...].
  var csrf = (document.querySelector('meta[name=csrf-token]') || {}).content;
  function collect(form) {
    var fd = new FormData(), lines = [];
    form.querySelectorAll('input, select, textarea').forEach(function (f) {
      if (!f.name || f.type === 'submit') return;
      if (f.type === 'file') { Array.prototype.forEach.call(f.files, function (file) { fd.append('lead[files][]', file); }); if (f.files.length) lines.push((f.getAttribute('data-label') || 'مرفقات') + ': ' + f.files.length); return; }
      if (f.name === 'website') { fd.append('website', f.value); return; }
      var val = f.value;
      if (f.tagName === 'SELECT' && f.multiple) val = Array.prototype.map.call(f.selectedOptions, function (o) { return o.value; }).filter(Boolean).join('، ');
      else if (f.tagName === 'SELECT' && f.selectedIndex === 0 && !f.options[0].value) val = '';
      if (/^lead\[/.test(f.name)) fd.append(f.name, val);
      else fd.append('lead[payload][' + f.name + ']', val);
      if (val) {
        var label = f.getAttribute('data-label') || f.getAttribute('placeholder') || (f.previousElementSibling && f.previousElementSibling.textContent) || f.name;
        lines.push(label.replace(/\*$/, '') + ': ' + val);
      }
    });
    fd.append('lead[kind]', form.getAttribute('data-kind') || 'contact');
    fd.append('lead[source]', (form.getAttribute('data-source') || '') + ' ' + location.pathname);
    // email typed in the phone field
    var phone = fd.get('lead[phone]');
    if (phone && phone.indexOf('@') > -1) { fd.set('lead[email]', phone); fd.set('lead[phone]', ''); }
    return { fd: fd, lines: lines };
  }
  function waLink(title, lines) {
    return WA_HREF + '?text=' + encodeURIComponent([title + ':'].concat(lines).join('\n'));
  }
  function submitLead(form, done, fail) {
    var data = collect(form);
    var btn = form.querySelector('[type=submit]');
    var msg = form.querySelector('[data-form-msg]');
    if (btn) { btn.disabled = true; btn.dataset.label = btn.textContent; btn.textContent = 'جارٍ الإرسال…'; }
    if (msg) { msg.textContent = ''; msg.className = 'form-msg'; }
    fetch('/leads', { method: 'POST', headers: { 'X-CSRF-Token': csrf, 'Accept': 'application/json' }, body: data.fd, credentials: 'same-origin' })
      .then(function (r) { return r.json().then(function (j) { j.__status = r.status; return j; }); })
      .then(function (j) {
        if (btn) { btn.disabled = false; btn.textContent = btn.dataset.label; }
        if (j.ok) { done(j, data); }
        else { if (msg) { msg.textContent = (j.errors || []).join('، ') || 'لم يتم الإرسال.'; msg.className = 'form-msg err'; } if (fail) fail(j, data); }
      })
      .catch(function () {
        if (btn) { btn.disabled = false; btn.textContent = btn.dataset.label; }
        if (msg) { msg.textContent = 'تعذر الاتصال بالخادم — تم تحويل طلبك إلى واتساب.'; msg.className = 'form-msg err'; }
        window.open(waLink(form.getAttribute('data-wa-title') || 'طلب من الموقع', data.lines), '_blank', 'noopener');
      });
  }
  document.querySelectorAll('form[data-lead-form]:not([data-kind=download])').forEach(function (form) {
    form.addEventListener('submit', function (e) {
      e.preventDefault();
      submitLead(form, function (j, data) {
        var success = form.querySelector('.form-success');
        if (success) {
          var wa = success.querySelector('[data-wa-prefill]');
          if (wa) wa.href = waLink(form.getAttribute('data-wa-title') || 'طلب من الموقع', data.lines);
          form.classList.add('is-sent');
          success.scrollIntoView({ behavior: 'smooth', block: 'center' });
        } else {
          var msg = form.querySelector('[data-form-msg]');
          if (msg) { msg.textContent = 'تم استلام طلبك. سيتواصل معك الفريق المختص.'; msg.className = 'form-msg ok'; }
          form.reset();
        }
      });
    });
  });

  // ---- gated downloads ----
  // <a data-gate="catalog-full" href="/downloads/catalog-full">: opens the modal once per browser (30 days cookie
  // set by the server + sessionStorage flag), then follows the link directly.
  var gate = document.getElementById('gate');
  var gateForm = gate && gate.querySelector('form');
  var gated = function () { try { return sessionStorage.getItem('mz_gate') === '1' || /(^|; )mz_gate=/.test(document.cookie); } catch (e) { return false; } };
  var pendingHref = null;
  function openGate(a) {
    pendingHref = a.getAttribute('href');
    gate.querySelector('[data-gate-key]').value = a.getAttribute('data-gate');
    gate.querySelector('[data-gate-title]').textContent = a.getAttribute('data-gate-title') || a.textContent.trim().replace(/\s*←$/, '');
    gate.hidden = false; body.style.overflow = 'hidden';
    var first = gate.querySelector('input:not([type=hidden]):not(.hp)'); if (first) first.focus();
  }
  function closeGate() { gate.hidden = true; body.style.overflow = ''; }
  if (gate) {
    document.addEventListener('click', function (e) {
      var a = e.target.closest('[data-gate]');
      if (!a || gated()) return;
      e.preventDefault(); openGate(a);
    });
    gate.querySelectorAll('[data-gate-close]').forEach(function (el) { el.addEventListener('click', closeGate); });
    document.addEventListener('keydown', function (e) { if (e.key === 'Escape' && !gate.hidden) closeGate(); });
    gateForm.addEventListener('submit', function (e) {
      e.preventDefault();
      submitLead(gateForm, function (j) {
        try { sessionStorage.setItem('mz_gate', '1'); } catch (err) {}
        closeGate(); gateForm.reset();
        window.open(j.file || pendingHref, '_blank', 'noopener');
      }, function () {});
    });
  }

  // ---- category page: sub-category + ready/custom filters ----
  var grid = document.querySelector('[data-product-grid]');
  if (grid) {
    var cards = Array.prototype.slice.call(grid.querySelectorAll('.product-card'));
    var count = document.querySelector('[data-product-count]');
    var empty = document.querySelector('[data-product-empty]');
    var state = { sub: (new URLSearchParams(location.search)).get('sub') || '', kind: (new URLSearchParams(location.search)).get('kind') || '' };
    function apply() {
      var n = 0;
      cards.forEach(function (c) {
        var ok = (!state.sub || c.getAttribute('data-sub') === state.sub) && (!state.kind || c.getAttribute('data-kind') === state.kind);
        c.classList.toggle('hidden', !ok); if (ok) n++;
      });
      if (count) count.textContent = (count.getAttribute('data-template') || '%{count} منتجات ظاهرة').replace('%{count}', n.toLocaleString(LOCALE));
      if (empty) empty.hidden = n > 0;
      document.querySelectorAll('[data-sub-filter]').forEach(function (b) { b.classList.toggle('active', b.getAttribute('data-sub-filter') === state.sub); });
      document.querySelectorAll('[data-kind-filter]').forEach(function (b) { b.classList.toggle('active', b.getAttribute('data-kind-filter') === state.kind); });
      var qs = new URLSearchParams(); if (state.sub) qs.set('sub', state.sub); if (state.kind) qs.set('kind', state.kind);
      history.replaceState(null, '', location.pathname + (qs.toString() ? '?' + qs : ''));
    }
    document.querySelectorAll('[data-sub-filter]').forEach(function (b) {
      b.addEventListener('click', function (e) { e.preventDefault(); var v = b.getAttribute('data-sub-filter'); state.sub = state.sub === v ? '' : v; apply(); });
    });
    document.querySelectorAll('[data-kind-filter]').forEach(function (b) {
      b.addEventListener('click', function () { state.kind = b.getAttribute('data-kind-filter'); apply(); });
    });
    apply();
  }

  // ---- product gallery thumbs ----
  document.querySelectorAll('[data-gallery]').forEach(function (g) {
    var main = g.querySelector('[data-gallery-main]'), cap = g.querySelector('[data-gallery-caption]');
    g.querySelectorAll('[data-gallery-thumb]').forEach(function (t) {
      t.addEventListener('click', function () {
        g.querySelectorAll('[data-gallery-thumb]').forEach(function (x) { x.classList.remove('active'); });
        t.classList.add('active');
        main.src = t.getAttribute('data-src'); main.alt = t.getAttribute('data-label');
        if (cap) cap.textContent = t.getAttribute('data-label');
      });
    });
  });

  // ---- B2C product finder ----
  var finder = document.querySelector('[data-finder]');
  if (finder) {
    finder.addEventListener('submit', function (e) {
      e.preventDefault();
      var cat = finder.querySelector('[name=q1]:checked');
      var use = finder.querySelector('[name=q3]:checked');
      var url = cat ? cat.value : '/products';
      var qs = [];
      if (use && use.value === 'commercial') qs.push('kind=custom');
      if (use && use.value !== 'commercial') qs.push('kind=ready');
      location.href = url + (qs.length ? (url.indexOf('?') > -1 ? '&' : '?') + qs.join('&') : '');
    });
  }

  // ---- safety guide library search/filter ----
  var lib = document.querySelector('[data-guide-library]');
  if (lib) {
    var q = lib.querySelector('[data-guide-search]'), sel = lib.querySelector('[data-guide-filter]');
    var items = Array.prototype.slice.call(lib.querySelectorAll('[data-guide]'));
    var none = lib.querySelector('[data-guide-empty]');
    var norm = function (s) { return (s || '').toLowerCase().replace(/[أإآ]/g, 'ا').replace(/ة/g, 'ه').replace(/ى/g, 'ي'); };
    function run() {
      var text = norm(q.value), cat = sel.value, n = 0;
      items.forEach(function (it) {
        var ok = (!cat || it.getAttribute('data-guide-cat') === cat) && (!text || norm(it.getAttribute('data-guide')).indexOf(text) > -1);
        it.hidden = !ok; if (ok) n++;
      });
      if (none) none.hidden = n > 0;
    }
    q.addEventListener('input', run); sel.addEventListener('change', run);
  }

  // ---- news topic filter (client-side, mirrors ?topic=) ----
  document.querySelectorAll('[data-topic-filter]').forEach(function (b) {
    b.addEventListener('click', function () {
      var v = b.getAttribute('data-topic-filter');
      document.querySelectorAll('[data-topic-filter]').forEach(function (x) { x.classList.toggle('active', x === b); });
      document.querySelectorAll('[data-topic]').forEach(function (c) { c.hidden = !!v && c.getAttribute('data-topic') !== v; });
    });
  });

  // ---- trust marquee ----
  var row = document.getElementById('marqueeRow');
  if (row) {
    var clients = JSON.parse(row.getAttribute('data-clients') || '[]');
    for (var g = 0; g < 2; g++) {
      var group = document.createElement('div'); group.className = 'marquee-group';
      clients.concat(clients).forEach(function (c) {
        var item = document.createElement('div'); item.className = 'marquee-item';
        var tile = document.createElement('div'); tile.className = 'marquee-logo'; tile.style.background = c.bg;
        var img = document.createElement('img'); img.src = c.logo; img.alt = c.name; img.loading = 'lazy'; tile.appendChild(img);
        var label = document.createElement('div'); label.className = 'marquee-label'; label.textContent = c.name;
        item.appendChild(tile); item.appendChild(label); group.appendChild(item);
      });
      row.appendChild(group);
    }
  }

  // ---- original vs counterfeit comparison slider ----
  var box = document.getElementById('cmp'), real = document.getElementById('cmpReal'), handle = document.getElementById('cmpHandle');
  if (box && real && handle) {
    var set = function (pct) { pct = Math.min(Math.max(pct, 4), 96); real.style.clipPath = 'inset(0 0 0 ' + pct + '%)'; handle.style.left = pct + '%'; };
    handle.addEventListener('pointerdown', function (e) {
      e.preventDefault();
      var r = box.getBoundingClientRect();
      var move = function (ev) { set(((ev.clientX - r.left) / r.width) * 100); };
      var up = function () { removeEventListener('pointermove', move); removeEventListener('pointerup', up); };
      addEventListener('pointermove', move); addEventListener('pointerup', up);
    });
  }

  // ---- splash (home only, once per session) ----
  var splash = document.getElementById('splash');
  if (splash) {
    var seen = false; try { seen = sessionStorage.getItem('mz_splash') === '1'; } catch (e) {}
    if (seen || matchMedia('(prefers-reduced-motion: reduce)').matches) { splash.remove(); }
    else {
      try { sessionStorage.setItem('mz_splash', '1'); } catch (e) {}
      body.style.overflow = 'hidden';
      var rig = document.getElementById('splashRig'), carrier = document.getElementById('splashCarrier'), tag = document.getElementById('splashTag');
      var H = innerHeight;
      var METAL = 'linear-gradient(180deg,#F2F4F8 0%,#C6CBD4 42%,#9AA0AB 55%,#DFE3EA 100%)';
      var METALV = 'linear-gradient(90deg,#F2F4F8 0%,#C6CBD4 42%,#9AA0AB 55%,#DFE3EA 100%)';
      var bar = function (css, delay, from) {
        var b = document.createElement('div');
        b.style.cssText = 'position:absolute;border-radius:3px;box-shadow:0 4px 14px rgba(0,0,0,.4);opacity:0;transition:transform .7s cubic-bezier(.2,.9,.3,1) ' + delay + 'ms, opacity .4s ease ' + delay + 'ms;transform:' + from + ';' + css;
        rig.appendChild(b); return b;
      };
      var bars = [], TW = 190, GAP = 300;
      [-1, 1].forEach(function (side) {
        var edge = side === -1 ? 'right:calc(50% + ' + (GAP / 2) + 'px)' : 'left:calc(50% + ' + (GAP / 2) + 'px)';
        bars.push(bar(edge + ';top:-2%;height:104%;width:9px;background:' + METALV, 100, 'translateY(' + (side * 40) + 'vh)'));
        bars.push(bar((side === -1 ? 'right' : 'left') + ':calc(50% + ' + (GAP / 2 + TW) + 'px);top:-2%;height:104%;width:9px;background:' + METALV, 220, 'translateY(' + (-side * 40) + 'vh)'));
        for (var i = 0; i < 6; i++) bars.push(bar(edge + ';top:' + (4 + i * 18) + '%;width:' + (TW + 9) + 'px;height:7px;background:' + METAL, 350 + i * 110, 'translateX(' + (side * 60) + 'vw)'));
        for (var k = 0; k < 5; k++) {
          var up = k % 2 === 0 ? 1 : -1;
          bars.push(bar(edge + ';top:' + (4 + k * 18 + 9) + '%;width:' + Math.hypot(TW, H * 0.18) + 'px;height:5px;background:' + METAL + ';transform-origin:' + (side === -1 ? '100%' : '0') + ' 50%;opacity:.9', 500 + k * 110, 'translateX(' + (side * 60) + 'vw) rotate(0deg)'));
          bars[bars.length - 1].dataset.rot = (side === -1 ? 1 : -1) * up * (Math.atan2(H * 0.18, TW) * 180 / Math.PI);
        }
      });
      bar('left:calc(50% - ' + (GAP / 2 + TW) + 'px);right:calc(50% - ' + (GAP / 2 + TW) + 'px);top:2.5%;height:10px;background:' + METAL + ';border-radius:4px', 900, 'translateY(-60px)');
      var cables = [-70, 70].map(function (x) {
        var c = document.createElement('div');
        c.style.cssText = 'position:absolute;left:calc(50% + ' + x + 'px);top:3.2%;width:3px;height:0;background:linear-gradient(180deg,#AEB4BE,#7E848E);opacity:0;transition:opacity .3s';
        rig.appendChild(c); return c;
      });
      requestAnimationFrame(function () { requestAnimationFrame(function () {
        bars.forEach(function (b) { b.style.transform = b.dataset.rot ? 'rotate(' + b.dataset.rot + 'deg)' : 'none'; b.style.opacity = '1'; });
      }); });
      var topY = H * 0.032, endY = H * 0.46, DESC = 2000;
      setTimeout(function () {
        cables.forEach(function (c) { c.style.opacity = '1'; });
        carrier.style.transform = 'translate(-50%, ' + topY + 'px)'; carrier.style.transition = 'transform .01s';
        requestAnimationFrame(function () {
          carrier.style.transition = 'transform ' + DESC + 'ms cubic-bezier(.35,0,.3,1)';
          carrier.style.transform = 'translate(-50%, ' + endY + 'px)';
          cables.forEach(function (c) { c.style.transition = 'height ' + DESC + 'ms cubic-bezier(.35,0,.3,1), opacity .3s'; c.style.height = (endY - topY + 20) + 'px'; });
        });
        setTimeout(function () { tag.style.opacity = '1'; }, DESC * 0.55);
      }, 1200);
      setTimeout(function () {
        splash.style.transition = 'transform 1.05s cubic-bezier(.65,0,.35,1)';
        splash.style.transform = 'translateY(102%)';
        setTimeout(function () { splash.remove(); body.style.overflow = ''; }, 1100);
      }, 1200 + DESC + 400);
    }
  }
})();
