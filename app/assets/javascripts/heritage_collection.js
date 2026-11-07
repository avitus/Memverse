(function () {
  'use strict';
  document.addEventListener('DOMContentLoaded', function () {
    var table = document.querySelector('[data-heritage-collection]');
    if (!table) return;
    var rows = Array.from(table.tBodies[0].rows), page = 1, sortIndex = -1, direction = 1;
    var search = document.getElementById('filter'), status = document.getElementById('heritage-status');
    var size = document.getElementById('heritage-page-size'), pageInput = document.getElementById('heritage-page');
    var checkAll = document.getElementById('checkAll'), form = document.getElementById('manage_verses_form');
    function matching() {
      var query = search.value.toLowerCase().trim();
      return rows.filter(function (row) { return row.textContent.toLowerCase().indexOf(query) !== -1 && (!status.value || row.cells[4].textContent.trim() === status.value); });
    }
    function render() {
      var matches = matching(), pageSize = Number(size.value), pages = Math.max(1, Math.ceil(matches.length / pageSize));
      page = Math.max(1, Math.min(pages, page));
      var visible = matches.slice((page - 1) * pageSize, page * pageSize);
      rows.forEach(function (row) { row.hidden = visible.indexOf(row) < 0; });
      var selected = rows.filter(function (row) { return row.querySelector('.boxes').checked; });
      var outside = selected.filter(function (row) { return matches.indexOf(row) < 0; }).length;
      document.getElementById('heritage-selection-count').textContent = selected.length + ' selected' + (outside ? ' · ' + outside + ' outside this filter' : '');
      document.getElementById('heritage-range').textContent = matches.length ? ((page - 1) * pageSize + 1) + '–' + Math.min(page * pageSize, matches.length) + ' of ' + matches.length : 'No matching verses';
      pageInput.value = page; pageInput.max = pages;
      document.getElementById('heritage-prev').disabled = page === 1;
      document.getElementById('heritage-next').disabled = page === pages;
      checkAll.checked = visible.length > 0 && visible.every(function (row) { return row.querySelector('.boxes').checked; });
      checkAll.indeterminate = !checkAll.checked && visible.some(function (row) { return row.querySelector('.boxes').checked; });
    }
    [search, status, size].forEach(function (control) { control.addEventListener(control === search ? 'input' : 'change', function () { page = 1; render(); }); });
    document.getElementById('heritage-prev').addEventListener('click', function () { page--; render(); });
    document.getElementById('heritage-next').addEventListener('click', function () { page++; render(); });
    pageInput.addEventListener('change', function () { page = Number(pageInput.value) || 1; render(); });
    pageInput.addEventListener('keydown', function (event) { if (event.key === 'Enter') { event.preventDefault(); page = Number(pageInput.value) || 1; render(); } });
    table.addEventListener('change', function (event) {
      if (event.target === checkAll) rows.filter(function (row) { return !row.hidden; }).forEach(function (row) { row.querySelector('.boxes').checked = checkAll.checked; });
      render();
    });
    document.getElementById('heritage-select-matching').addEventListener('click', function () { matching().forEach(function (row) { row.querySelector('.boxes').checked = true; }); render(); });
    document.getElementById('heritage-clear-selection').addEventListener('click', function () { rows.forEach(function (row) { row.querySelector('.boxes').checked = false; }); render(); });
    function detail() { table.classList.toggle('heritage-compact', document.getElementById('heritage-detail').value === 'compact'); }
    document.getElementById('heritage-detail').addEventListener('change', detail);
    table.querySelectorAll('thead a').forEach(function (link) {
      link.addEventListener('click', function (event) {
        event.preventDefault(); var index = link.closest('th').cellIndex;
        direction = sortIndex === index ? -direction : 1; sortIndex = index;
        rows.sort(function (a, b) { return direction * (a.cells[index].getAttribute('data-sort') || a.cells[index].textContent.trim()).localeCompare(b.cells[index].getAttribute('data-sort') || b.cells[index].textContent.trim(), undefined, {numeric:true}); });
        rows.forEach(function (row) { table.tBodies[0].appendChild(row); });
        table.querySelectorAll('th').forEach(function (th) { th.removeAttribute('aria-sort'); });
        link.closest('th').setAttribute('aria-sort', direction === 1 ? 'ascending' : 'descending'); render();
      });
    });
    var clickedAction;
    form.addEventListener('click', function (event) { if (event.target.type === 'submit') clickedAction = event.target.name; });
    form.addEventListener('submit', function (event) {
      var count = rows.filter(function (row) { return row.querySelector('.boxes').checked; }).length;
      if (!count) { event.preventDefault(); document.getElementById('heritage-selection-count').textContent = 'Select at least one verse.'; return; }
      var action = event.submitter ? event.submitter.name : clickedAction;
      if (action === 'Delete' && !window.confirm('Delete ' + count + ' selected verse' + (count === 1 ? '?' : 's?'))) { event.preventDefault(); return; }
      form.action = action === 'Delete' ? '/delete_memverses' : '/handle_verse_action';
    });
    document.addEventListener('heritage:collection-update', render);
    detail(); render();
  });
}());
