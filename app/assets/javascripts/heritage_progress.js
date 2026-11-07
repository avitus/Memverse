(function () {
  'use strict';
  document.addEventListener('DOMContentLoaded', function () {
    document.querySelectorAll('[data-heritage-chart]').forEach(function (section) {
      var memory = section.getAttribute('data-heritage-chart') === 'memory', chart, data;
      var status = section.querySelector('[data-chart-status]'), retry = section.querySelector('[data-chart-retry]');
      var range = section.querySelector('[data-chart-range]');
      function render() {
        var theme = getComputedStyle(document.body), ink = theme.getPropertyValue('--mv-ink').trim(), muted = theme.getPropertyValue('--mv-muted').trim(), border = theme.getPropertyValue('--mv-border').trim();
        var dates = data[memory ? 3 : 1], cutoff = new Date(); cutoff.setFullYear(cutoff.getFullYear() - 1);
        var indices = dates.map(function (_, i) { return i; }).filter(function (i) { return !range || range.value === 'all' || new Date(dates[i] + 'T00:00:00') >= cutoff; });
        var names = memory ? ['Memorized', 'Learning', 'Review minutes'] : ['Sessions in preceding year'];
        var values = memory ? [data[1], data[0], data[2]] : [data[0]];
        var colors = memory ? [theme.getPropertyValue('--mv-brand').trim(), '#8197ae', theme.getPropertyValue('--mv-action').trim()] : [theme.getPropertyValue('--mv-success').trim()];
        var series = names.map(function (name, i) { return {name:name, data:indices.map(function (j) { return Number(values[i][j]); }), color:colors[i], type: memory && i > 0 ? 'line' : 'area', fillOpacity:0.09, dashStyle:memory && i === 1 ? 'ShortDash' : 'Solid', yAxis:memory && i === 2 ? 1 : 0}; });
        if (chart) chart.destroy();
        status.textContent = indices.length ? '' : 'No history in this period. Choose All time to see earlier reviews.';
        chart = new Highcharts.Chart({chart:{renderTo:memory ? 'heritage-progress':'heritage-consistency',backgroundColor:'transparent',style:{fontFamily:'Arial, sans-serif'}},title:{text:null},legend:{itemStyle:{color:ink},itemHoverStyle:{color:ink}},credits:{enabled:false},xAxis:{lineColor:border,tickColor:border,labels:{style:{color:theme.getPropertyValue('--mv-action').trim()}},categories:indices.map(function (i) { return dates[i]; }),tickInterval:Math.max(1,Math.ceil(indices.length / (window.innerWidth < 700 ? 3 : 5)))},yAxis:memory ? [{title:{text:'Verses',style:{color:muted}},labels:{style:{color:muted}},gridLineColor:border,min:0},{title:{text:'Review minutes',style:{color:muted}},labels:{style:{color:muted}},gridLineColor:border,opposite:true,min:0}] : [{title:{text:'Sessions',style:{color:muted}},labels:{style:{color:muted}},gridLineColor:border,allowDecimals:false,min:0}],plotOptions:{series:{marker:{enabled:indices.length === 1,radius:4},lineWidth:2,animation:false}},series:series});
        var table = document.createElement('table'); table.className = 'memverse-standard';
        var caption = table.createCaption(); caption.textContent = memory ? 'Memorization history' : 'Consistency history';
        var head = table.createTHead().insertRow();
        ['Date'].concat(names).forEach(function (label) { var th=document.createElement('th'); th.scope='col'; th.textContent=label; head.appendChild(th); });
        var body=table.createTBody(); indices.forEach(function (i) { var row=body.insertRow(); [dates[i]].concat(values.map(function (v) { return v[i]; })).forEach(function (v) { row.insertCell().textContent=v; }); });
        var target=section.querySelector('[data-chart-table]'); target.textContent=''; target.appendChild(table);
      }
      function load() {
        retry.hidden=true; status.textContent='Loading your history…';
        $.getJSON(memory ? '/load_progress.json':'/load_consistency_progress.json').done(function (result) { data=result; render(); }).fail(function () { status.textContent='Your history couldn’t be loaded.'; retry.hidden=false; });
      }
      document.addEventListener('heritage:theme',function(){if(data) render();});
      retry.addEventListener('click',load); if(range) range.addEventListener('change',function(){if(data) render();}); load();
    });
  });
}());
