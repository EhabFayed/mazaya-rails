// Admin: repeatable JSON rows (add / remove / reorder), image label inputs, confirm dialogs.
(function () {
  'use strict';

  // <div data-rows="features"><template>...</template><div class="rows"></div><button data-add>...</button></div>
  // Rows are rendered server-side with name="model[field][INDEX][col]"; the template uses __i__.
  document.querySelectorAll('[data-rows]').forEach(function (box) {
    var list = box.querySelector('.rows'), tpl = box.querySelector('template'), add = box.querySelector('[data-add]');
    function reindex() {
      Array.prototype.forEach.call(list.children, function (row, i) {
        row.querySelectorAll('[name]').forEach(function (f) { f.name = f.name.replace(/\[\d+|__i__\]/, '[' + i + ']').replace(/\[(\d+|__i__)\](?=\[[^\]]+\]$)/, '[' + i + ']'); });
      });
    }
    function wire(row) {
      row.querySelector('[data-del]').addEventListener('click', function () { row.remove(); reindex(); });
      row.querySelector('[data-up]').addEventListener('click', function () { if (row.previousElementSibling) list.insertBefore(row, row.previousElementSibling); reindex(); });
      row.querySelector('[data-down]').addEventListener('click', function () { if (row.nextElementSibling) list.insertBefore(row.nextElementSibling, row); reindex(); });
    }
    Array.prototype.forEach.call(list.children, wire);
    if (add && tpl) add.addEventListener('click', function () {
      var html = tpl.innerHTML.replace(/__i__/g, String(list.children.length));
      var wrap = document.createElement('div'); wrap.innerHTML = html.trim();
      var row = wrap.firstElementChild; list.appendChild(row); wire(row); reindex();
      var first = row.querySelector('input,textarea'); if (first) first.focus();
    });
  });

  document.querySelectorAll('[data-confirm]').forEach(function (el) {
    el.addEventListener('click', function (e) { if (!confirm(el.getAttribute('data-confirm'))) { e.preventDefault(); e.stopImmediatePropagation(); } }, true);
  });

  // slug helper: fill slug from Latin name if empty
  var nameEn = document.querySelector('[data-slug-source]'), slug = document.querySelector('[data-slug-target]');
  if (nameEn && slug) nameEn.addEventListener('blur', function () {
    if (!slug.value) slug.value = nameEn.value.toLowerCase().replace(/&/g, ' and ').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
  });

  // preview selected images before upload
  document.querySelectorAll('input[type=file][data-preview]').forEach(function (inp) {
    inp.addEventListener('change', function () {
      var box = document.querySelector(inp.getAttribute('data-preview')); if (!box) return;
      box.innerHTML = '';
      Array.prototype.forEach.call(inp.files, function (f) {
        if (!f.type.match(/^image\//)) return;
        var img = document.createElement('img'); img.src = URL.createObjectURL(f); img.style.cssText = 'height:70px;border-radius:8px;object-fit:cover'; box.appendChild(img);
      });
    });
  });
})();
