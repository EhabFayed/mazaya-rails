// Shared behavior for Mazaya pages: WhatsApp wiring, menu, reveals, counters, forms.
(function () {
  'use strict';

  var WA_DISPLAY = '+966 50 000 0000';
  var WA_HREF = 'https://wa.me/' + WA_DISPLAY.replace(/[^0-9]/g, '');
  window.MAZAYA_WA = { display: WA_DISPLAY, href: WA_HREF };

  document.querySelectorAll('[data-wa]').forEach(function (a) {
    a.href = WA_HREF; a.target = '_blank'; a.rel = 'noopener';
  });
  document.querySelectorAll('[data-wa-display]').forEach(function (el) { el.textContent = WA_DISPLAY; });

  var menuBtn = document.querySelector('.menu-btn');
  var mobileNav = document.querySelector('.mobile-nav');
  if (menuBtn && mobileNav) {
    menuBtn.addEventListener('click', function () { mobileNav.classList.toggle('open'); });
    mobileNav.addEventListener('click', function (e) { if (e.target.tagName === 'A') mobileNav.classList.remove('open'); });
  }

  // scroll reveals
  var reveals = document.querySelectorAll('[data-reveal]');
  reveals.forEach(function (el) {
    el.style.opacity = '0';
    el.style.transform = 'translateY(28px)';
    el.style.transition = 'opacity .8s ease, transform .8s ease';
  });
  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (en) {
      if (en.isIntersecting) { en.target.style.opacity = '1'; en.target.style.transform = 'none'; io.unobserve(en.target); }
    });
  }, { threshold: 0.12 });
  reveals.forEach(function (el) { io.observe(el); });

  // counters
  var cio = new IntersectionObserver(function (entries) {
    entries.forEach(function (en) {
      if (!en.isIntersecting) return;
      var el = en.target, target = +el.getAttribute('data-count'), t0 = performance.now();
      var tick = function (now) {
        var p = Math.min((now - t0) / 1600, 1), e = 1 - Math.pow(1 - p, 3);
        el.textContent = Math.round(target * e).toLocaleString('ar-EG');
        if (p < 1) requestAnimationFrame(tick);
      };
      requestAnimationFrame(tick);
      cio.unobserve(el);
    });
  }, { threshold: 0.5 });
  document.querySelectorAll('[data-count]').forEach(function (el) { cio.observe(el); });

  // forms: [data-wa-form="subject"] — opens WhatsApp with the filled fields
  document.querySelectorAll('form[data-wa-form]').forEach(function (form) {
    form.addEventListener('submit', function (e) {
      e.preventDefault();
      var lines = [form.getAttribute('data-wa-form') + ':'];
      form.querySelectorAll('input, select, textarea').forEach(function (f) {
        var label = f.getAttribute('placeholder') || (f.tagName === 'SELECT' ? f.options[0].text : '');
        var val = f.value;
        if (!val) return;
        if (f.tagName === 'SELECT' && val === f.options[0].text) return;
        lines.push(label + ': ' + val);
      });
      window.open(WA_HREF + '?text=' + encodeURIComponent(lines.join('\n')), '_blank', 'noopener');
    });
  });
})();
