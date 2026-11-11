// Mazaya shared behaviour: WhatsApp wiring, menus, reveals, counters,
// lead forms (POST /leads with WhatsApp fallback), gated downloads,
// client-side filters (category page, product finder, guide library).
(function () {
  'use strict';

  var body = document.body;
  var LOCALE = 'en'; // Western digits everywhere (client request); Arabic text is unaffected
  var WA_DISPLAY = body.getAttribute('data-whatsapp-display') || '+966 50 000 0000';
  var WA_HREF = body.getAttribute('data-whatsapp-href') || ('https://wa.me/' + WA_DISPLAY.replace(/[^0-9]/g, ''));
  window.MAZAYA_WA = { display: WA_DISPLAY, href: WA_HREF };

  // data-wa-text="..." pre-fills the chat (e.g. the product's name and link on product pages)
  document.querySelectorAll('[data-wa]').forEach(function (a) {
    var text = a.getAttribute('data-wa-text');
    a.href = text ? WA_HREF + (WA_HREF.indexOf('?') > -1 ? '&' : '?') + 'text=' + encodeURIComponent(text) : WA_HREF;
    a.target = '_blank'; a.rel = 'noopener';
  });
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
      if (!en.isIntersecting) return;
      var el = en.target;
      el.style.opacity = '1'; el.style.transform = 'none'; io.unobserve(el);
      // Once revealed, drop the inline styles so class hover transitions (.card-hover lift + shadow) apply again
      el.addEventListener('transitionend', function done(e) {
        if (e.target !== el || e.propertyName !== 'transform') return;
        el.removeEventListener('transitionend', done);
        el.style.removeProperty('opacity'); el.style.removeProperty('transform'); el.style.removeProperty('transition');
      });
    });
  }, { threshold: 0.12 });
  reveals.forEach(function (el) { io.observe(el); });

  // ---- hover-expanding card pairs (.expand-pair) ----
  // Narrowing a card re-wraps its text and changes the row height; pin the row to its resting
  // height while hovered so the content below does not jump. The resting height is recorded
  // ahead of time: by the time pointerenter fires the hover styles already apply.
  document.querySelectorAll('.expand-pair').forEach(function (pair) {
    var rest = 0;
    var record = function () { if (!pair.style.height && !pair.matches(':hover')) rest = pair.offsetHeight; };
    record();
    if (window.ResizeObserver) new ResizeObserver(record).observe(pair);
    pair.addEventListener('pointerenter', function () { if (rest) pair.style.height = rest + 'px'; });
    pair.addEventListener('pointerleave', function () { pair.style.height = ''; record(); });
  });

  // ---- row index with swapping background ([data-bg-index], about → product range) ----
  // Hovering/focusing a row shows its photo as the section background and fills the caption.
  document.querySelectorAll('[data-bg-index]').forEach(function (root) {
    var items = root.querySelectorAll('[data-bg-item]');
    var imgs = root.querySelectorAll('[data-bg-img]');
    var name = root.querySelector('[data-bg-name]');
    var about = root.querySelector('[data-bg-about]');
    var cta = root.querySelector('[data-bg-cta]');
    var activate = function (i) {
      items.forEach(function (el, k) { el.classList.toggle('is-active', k === i); });
      imgs.forEach(function (el, k) { el.classList.toggle('is-shown', k === i); });
      if (name) name.textContent = items[i].dataset.name;
      if (about) about.textContent = items[i].dataset.about;
      if (cta) cta.setAttribute('href', items[i].getAttribute('href'));
    };
    items.forEach(function (el, i) {
      el.addEventListener('mouseenter', function () { activate(i); });
      el.addEventListener('focus', function () { activate(i); });
    });
  });

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
      if (f.name === 'mz_trap') { fd.append('mz_trap', f.value); return; }   // honeypot, not shown in the WhatsApp text
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
  function closeGate() { gate.hidden = true; body.style.overflow = ''; if (gateForm) gateForm.classList.remove('is-done'); }
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
        var file = j.file || pendingHref;
        gateForm.reset();
        // lead saved: show the confirmation with a real download link, and start the download.
        // A download link click (not window.open) is not treated as a popup, so browsers don't block it.
        var link = gateForm.querySelector('[data-gate-file]');
        link.href = file;
        gateForm.classList.add('is-done');
        var a = document.createElement('a');
        a.href = file; a.download = ''; a.rel = 'noopener';
        document.body.appendChild(a); a.click(); a.remove();
        link.focus();
      }, function () {});
    });
  }

  // ---- category nav: on mobile it is a swipe row, so bring the current category into view ----
  // Relative delta keeps it correct in both RTL and LTR scroll coordinates.
  document.querySelectorAll('.cat-nav .tab.active').forEach(function (tab) {
    var row = tab.parentElement;
    if (row.scrollWidth <= row.clientWidth) return;
    var t = tab.getBoundingClientRect(), r = row.getBoundingClientRect();
    row.scrollLeft += (t.left + t.width / 2) - (r.left + r.width / 2);
  });

  // ---- category page: search + ready/custom + sub-category filters, sort ----
  // Facet counts on each button follow the other active filters, so they always
  // say how many products clicking would show. State lives in the URL (?q ?kind ?sub ?sort).
  var grid = document.querySelector('[data-product-grid]');
  if (grid) {
    var cards = Array.prototype.slice.call(grid.querySelectorAll('.product-card'));
    var count = document.querySelector('[data-product-count]');
    var empty = document.querySelector('[data-product-empty]');
    var qInput = document.querySelector('[data-filter-q]');
    var sortSel = document.querySelector('[data-filter-sort]');
    var chips = document.querySelector('[data-active-filters]');
    var resets = document.querySelectorAll('[data-filter-reset]');
    var bar = document.querySelector('[data-product-filters]');
    var params = new URLSearchParams(location.search);
    // ?kind= is the entry mode (custom from منتجات حسب الطلب; B2B pages pass none and land on "all"):
    // it survives reloads and every reset goes back to it rather than to "all"
    var entryKind = /^(ready|custom)$/.test(params.get('kind')) ? params.get('kind') : '';
    var defaultKind = entryKind;
    var state = { sub: params.get('sub') || '', kind: defaultKind, q: params.get('q') || '', sort: params.get('sort') || '' };
    if (qInput) qInput.value = state.q;
    if (sortSel) sortSel.value = state.sort;
    cards.forEach(function (c, i) { c._i = i; });

    function norm(s) { return (s || '').toLowerCase().replace(/[ً-ٰٟـ]/g, '').replace(/[أإآ]/g, 'ا').replace(/ة/g, 'ه').replace(/ى/g, 'ي').trim(); }
    // each kind button shows only its own products; "general" ones carry no label and show under both
    function kindOk(c, k) { var ck = c.getAttribute('data-kind'); return !k || ck === k || ck === 'general'; }
    function matches(c, skip) {
      var q = norm(state.q);
      return (skip === 'sub' || !state.sub || c.getAttribute('data-sub') === state.sub) &&
             (skip === 'kind' || kindOk(c, state.kind)) &&
             (!q || norm(c.getAttribute('data-search')).indexOf(q) > -1);
    }
    function facet(btn, n) {
      var b = btn.querySelector('[data-facet]'); if (b) b.textContent = n.toLocaleString(LOCALE);
      btn.toggleAttribute('data-empty-facet', n === 0 && !btn.classList.contains('active'));
    }
    function labelFor(sel, fallback) { var b = document.querySelector(sel + '[data-label]'); return b ? b.getAttribute('data-label') : fallback; }
    function chip(text, clear) {
      var b = document.createElement('button');
      b.type = 'button'; b.className = 'pfx-chip';
      b.setAttribute('aria-label', (chips.getAttribute('data-remove-label') || '×') + ': ' + text);
      b.textContent = text;
      var x = document.createElement('i'); x.setAttribute('aria-hidden', 'true'); x.textContent = '×'; b.appendChild(x);
      b.addEventListener('click', function () { clear(); apply(); });
      chips.appendChild(b);
    }

    // Show PAGE cards at a time; any filter change starts again from the first page.
    var PAGE = 9, limit = PAGE;
    var more = document.querySelector('[data-load-more]');
    function apply(keepLimit) {
      if (keepLimit !== true) limit = PAGE;
      var order = cards.slice();
      if (state.sort === 'name') order.sort(function (a, b) { return a.getAttribute('data-name').localeCompare(b.getAttribute('data-name'), document.documentElement.lang || 'ar'); });
      else order.sort(function (a, b) { return a._i - b._i; });

      var n = 0, shown = 0;
      order.forEach(function (c) {
        grid.appendChild(c);
        var ok = matches(c), show = ok && shown < limit;
        c.classList.toggle('hidden', !show);
        if (ok) n++;
        if (show) shown++;
      });
      if (more) {
        more.hidden = shown >= n;
        var label = more.querySelector('[data-load-more-label]');
        if (label) label.textContent = (label.getAttribute('data-template') || '%{count}').replace('%{count}', (n - shown).toLocaleString(LOCALE));
      }

      document.querySelectorAll('[data-kind-filter]').forEach(function (b) {
        var v = b.getAttribute('data-kind-filter'), on = v === state.kind;
        b.classList.toggle('active', on); b.setAttribute('aria-pressed', on);
        facet(b, cards.filter(function (c) { return matches(c, 'kind') && kindOk(c, v); }).length);
      });
      document.querySelectorAll('[data-sub-filter]').forEach(function (b) {
        var v = b.getAttribute('data-sub-filter'), on = v === state.sub;
        b.classList.toggle('active', on); if (b.tagName === 'BUTTON') b.setAttribute('aria-pressed', on);
        facet(b, cards.filter(function (c) { return matches(c, 'sub') && (!v || c.getAttribute('data-sub') === v); }).length);
      });

      if (count) count.textContent = (count.getAttribute('data-template') || '%{count} منتجات ظاهرة').replace('%{count}', n.toLocaleString(LOCALE));
      if (empty) empty.hidden = n > 0;
      if (chips) {
        chips.innerHTML = '';
        if (state.q) chip('«' + state.q + '»', function () { state.q = ''; if (qInput) qInput.value = ''; });
        if (state.kind && state.kind !== defaultKind) chip(labelFor('[data-kind-filter="' + state.kind + '"]', state.kind), function () { state.kind = defaultKind; });
        if (state.sub) chip(labelFor('button[data-sub-filter="' + state.sub + '"]', state.sub), function () { state.sub = ''; });
      }
      var any = !!(state.q || state.kind !== defaultKind || state.sub);
      resets.forEach(function (r) { if (!r.closest('[data-product-empty]')) r.hidden = !any; });
    }
    function reset() {
      state.sub = state.q = state.sort = ''; state.kind = defaultKind;
      if (qInput) qInput.value = '';
      if (sortSel) sortSel.value = '';
      apply();
    }

    document.querySelectorAll('[data-sub-filter]').forEach(function (b) {
      b.addEventListener('click', function (e) {
        e.preventDefault();
        var v = b.getAttribute('data-sub-filter');
        state.sub = (b.tagName !== 'BUTTON' && state.sub === v) ? '' : v; // header chips toggle; bar buttons select
        apply();
        if (b.hasAttribute('data-jump') && bar) bar.scrollIntoView({ behavior: 'smooth', block: 'center' });
      });
    });
    document.querySelectorAll('[data-kind-filter]').forEach(function (b) {
      b.addEventListener('click', function () { state.kind = b.getAttribute('data-kind-filter'); apply(); });
    });
    if (qInput) {
      var t;
      qInput.addEventListener('input', function () { clearTimeout(t); t = setTimeout(function () { state.q = qInput.value.trim(); apply(); }, 180); });
      qInput.addEventListener('keydown', function (e) { if (e.key === 'Escape') { qInput.value = ''; state.q = ''; apply(); } });
    }
    if (sortSel) sortSel.addEventListener('change', function () { state.sort = sortSel.value; apply(); });
    resets.forEach(function (r) {
      r.addEventListener('click', function () {
        state.sub = state.q = ''; state.kind = defaultKind; if (qInput) qInput.value = '';
        apply(); if (qInput) qInput.focus({ preventScroll: true });
      });
    });
    if (more) more.addEventListener('click', function () {
      var first = grid.querySelectorAll('.product-card:not(.hidden)').length;
      limit += PAGE; apply(true);
      var next = grid.querySelectorAll('.product-card:not(.hidden)')[first];
      if (next) next.focus({ preventScroll: true }); // keyboard users land on the first new card
    });
    apply();
    // Filters last only while on the page: links may preset them (?sub= ?kind= ?q= ?sort=), but the
    // URL is cleaned right away (except the ?kind= entry mode), and coming Back starts from that mode.
    if (location.search) history.replaceState(null, '', location.pathname + (entryKind ? '?kind=' + entryKind : '') + location.hash);
    window.addEventListener('pageshow', function (e) {
      if (e.persisted || (performance.getEntriesByType('navigation')[0] || {}).type === 'back_forward') reset();
    });
  }

  // ---- product gallery: thumbs + full-screen viewer ----
  document.querySelectorAll('[data-gallery]').forEach(function (g) {
    var main = g.querySelector('[data-gallery-main]'), cap = g.querySelector('[data-gallery-caption]');
    var thumbs = Array.prototype.slice.call(g.querySelectorAll('[data-gallery-thumb]'));
    if (!main) return;
    var current = 0;

    function show(i) {
      current = i;
      var t = thumbs[i];
      if (!t) return;
      thumbs.forEach(function (x) { x.classList.remove('active'); });
      t.classList.add('active');
      main.src = t.getAttribute('data-src'); main.alt = t.getAttribute('data-label');
      if (cap) cap.textContent = t.getAttribute('data-label');
    }
    thumbs.forEach(function (t, i) {
      t.addEventListener('click', function () { show(i); });
      t.addEventListener('keydown', function (e) { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); show(i); } });
    });

    var chev = '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 18l-6-6 6-6"/></svg>';
    var lb = document.createElement('div');
    lb.className = 'lb';
    lb.setAttribute('role', 'dialog'); lb.setAttribute('aria-modal', 'true');
    lb.innerHTML =
      '<img class="lb-img" alt="">' +
      '<button type="button" class="lb-close" aria-label="' + (g.dataset.labelClose || 'Close') + '"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" aria-hidden="true"><path d="M18 6L6 18M6 6l12 12"/></svg></button>' +
      '<button type="button" class="lb-prev" aria-label="' + (g.dataset.labelPrev || 'Previous') + '">' + chev + '</button>' +
      '<button type="button" class="lb-next" aria-label="' + (g.dataset.labelNext || 'Next') + '">' + chev.replace('M15 18l-6-6 6-6', 'M9 18l6-6-6-6') + '</button>' +
      '<div class="lb-bar"><b></b><span></span></div>';
    document.body.appendChild(lb);
    var lbImg = lb.querySelector('.lb-img'), lbCount = lb.querySelector('.lb-bar b'), lbCap = lb.querySelector('.lb-bar span');
    var prevBtn = lb.querySelector('.lb-prev'), nextBtn = lb.querySelector('.lb-next'), lastFocus = null;
    var many = thumbs.length > 1;
    prevBtn.hidden = nextBtn.hidden = !many;

    function render() {
      var t = thumbs[current];
      lbImg.src = t ? t.getAttribute('data-src') : main.src;
      lbImg.alt = t ? t.getAttribute('data-label') : main.alt;
      lbCap.textContent = lbImg.alt;
      lbCount.textContent = many ? (current + 1) + ' / ' + thumbs.length : '';
    }
    function step(d) {
      if (!many) return;
      show((current + d + thumbs.length) % thumbs.length);
      render();
    }
    function open() {
      lastFocus = document.activeElement;
      render();
      lb.classList.add('open');
      document.body.classList.add('lb-lock');
      lb.querySelector('.lb-close').focus();
    }
    function close() {
      lb.classList.remove('open');
      document.body.classList.remove('lb-lock');
      if (lastFocus) lastFocus.focus();
    }

    main.addEventListener('click', open);
    var openBtn = g.querySelector('[data-gallery-open]');
    if (openBtn) openBtn.addEventListener('click', open);
    lb.querySelector('.lb-close').addEventListener('click', close);
    prevBtn.addEventListener('click', function () { step(-1); });
    nextBtn.addEventListener('click', function () { step(1); });
    lb.addEventListener('click', function (e) { if (e.target === lb) close(); });

    var rtl = document.documentElement.dir === 'rtl';
    document.addEventListener('keydown', function (e) {
      if (!lb.classList.contains('open')) return;
      if (e.key === 'Escape') close();
      else if (e.key === 'ArrowRight') step(rtl ? -1 : 1);
      else if (e.key === 'ArrowLeft') step(rtl ? 1 : -1);
      else if (e.key === 'Tab') { // keep focus inside the dialog
        var f = Array.prototype.filter.call(lb.querySelectorAll('button'), function (b) { return !b.hidden; });
        var i = f.indexOf(document.activeElement);
        e.preventDefault();
        f[(i + (e.shiftKey ? -1 : 1) + f.length) % f.length].focus();
      }
    });

    var x0 = null;
    lb.addEventListener('touchstart', function (e) { x0 = e.touches[0].clientX; }, { passive: true });
    lb.addEventListener('touchend', function (e) {
      if (x0 === null) return;
      var dx = e.changedTouches[0].clientX - x0; x0 = null;
      if (Math.abs(dx) > 45) step((dx < 0) !== rtl ? 1 : -1);
    });
  });

  // ---- B2C product finder ----
  var finder = document.querySelector('[data-finder]');
  if (finder) {
    finder.addEventListener('submit', function (e) {
      e.preventDefault();
      // the finder lives on منتجات حسب الطلب, so every answer lands on the custom (B2C) list;
      // the category options already carry ?kind=custom
      var cat = finder.querySelector('[name=q1]:checked');
      location.href = cat ? cat.value : '/products';
    });
  }

  // ---- safety guide library search/filter ----
  var lib = document.querySelector('[data-guide-library]');
  if (lib) {
    var q = lib.querySelector('[data-guide-search]'), sel = lib.querySelector('[data-guide-filter]');
    var items = Array.prototype.slice.call(lib.querySelectorAll('[data-guide]'));
    var none = lib.querySelector('[data-guide-empty]');
    var norm = function (s) { return (s || '').toLowerCase().replace(/[ً-ٰٟـ]/g, '').replace(/[أإآ]/g, 'ا').replace(/ة/g, 'ه').replace(/ى/g, 'ي'); };
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

  // ---- clients carousel: arrows (one page), swipe / mouse drag, autoplay (one logo) ----
  document.querySelectorAll('[data-carousel]').forEach(function (car) {
    var track = car.querySelector('[data-cc-track]');
    if (!track || !track.children.length) return;
    // modern browsers report RTL scrollLeft as 0 → negative; work in "distance from start"
    var sign = getComputedStyle(track).direction === 'rtl' ? -1 : 1;
    var pos = function () { return Math.abs(track.scrollLeft); };
    var max = function () { return track.scrollWidth - track.clientWidth; };
    var tileW = function () {
      var a = track.children[0], b = track.children[1];
      return b ? Math.abs(b.offsetLeft - a.offsetLeft) : a.offsetWidth;
    };
    var go = function (dist) { track.scrollTo({ left: sign * Math.min(Math.max(dist, 0), max()) }); };
    var step = function (tiles) {
      if (tiles > 0 && pos() >= max() - 2) return go(0);            // loop: end → start
      if (tiles < 0 && pos() <= 2) return go(max());                 // loop: start → end
      go(Math.round((pos() + tiles * tileW()) / tileW()) * tileW());
    };
    var page = function () { return Math.max(1, Math.round(track.clientWidth / tileW())); };

    // autoplay; pauses on hover / focus / interaction, resumes after a short idle
    var reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
    var timer = null, hold = false, idle = null;
    var play = function () { if (!reduce && !timer) timer = setInterval(function () { if (!hold && !document.hidden) step(1); }, 3000); };
    var stop = function () { clearInterval(timer); timer = null; };
    var nudge = function () { stop(); clearTimeout(idle); idle = setTimeout(play, 6000); };
    car.addEventListener('mouseenter', function () { hold = true; });
    car.addEventListener('mouseleave', function () { hold = false; });
    car.addEventListener('focusin', function () { hold = true; });
    car.addEventListener('focusout', function () { hold = false; });
    track.addEventListener('touchstart', nudge, { passive: true });
    track.addEventListener('wheel', nudge, { passive: true });

    car.querySelectorAll('[data-cc-step]').forEach(function (b) {
      b.addEventListener('click', function () { nudge(); step(parseInt(b.getAttribute('data-cc-step'), 10) * page()); });
    });

    // mouse drag (touch already scrolls natively)
    track.addEventListener('pointerdown', function (e) {
      if (e.pointerType !== 'mouse' || e.button !== 0) return;
      var x0 = e.clientX, s0 = track.scrollLeft;
      nudge(); track.classList.add('dragging');
      var move = function (ev) { track.scrollLeft = s0 - (ev.clientX - x0); };
      var up = function () {
        removeEventListener('pointermove', move); removeEventListener('pointerup', up);
        track.classList.remove('dragging');
        go(Math.round(pos() / tileW()) * tileW());                   // settle on a logo
      };
      addEventListener('pointermove', move); addEventListener('pointerup', up);
    });

    play();
  });

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
