import {describe,it,expect,beforeEach,vi} from 'vitest';
import fs from 'fs';
new Function(fs.readFileSync('app/assets/javascripts/heritage_collection.js','utf8'))();

describe('Heritage verse collection',()=>{
  beforeEach(()=>{
    document.body.innerHTML='<input id="filter"><select id="heritage-status"><option value="">All</option><option>Pending</option></select><select id="heritage-detail"><option value="compact">Compact</option><option value="all">All details</option></select><span id="heritage-selection-count"></span><span id="heritage-range"></span><button id="heritage-select-matching"></button><button id="heritage-clear-selection"></button><select id="heritage-page-size"><option>25</option><option>50</option><option>100</option></select><input id="heritage-page"><button id="heritage-prev"></button><button id="heritage-next"></button><form id="manage_verses_form"><table data-heritage-collection><thead><tr><th><input type="checkbox" id="checkAll"></th><th><a href="/manage_verses">Verse</a></th></tr></thead><tbody></tbody></table></form>';
    const body=document.querySelector('tbody');
    for(let i=0;i<55;i++){const row=body.insertRow();for(let c=0;c<13;c++)row.insertCell().textContent=c===4?(i%2?'Pending':'Learning'):c===1?'John 3:'+String(i+1):'';row.cells[0].innerHTML='<input class="boxes" type="checkbox" name="mv[]" value="'+i+'">';}
    document.dispatchEvent(new Event('DOMContentLoaded'));
  });
  it('retains selection across pagination and filters and adds all matching',()=>{
    const first=document.querySelector('.boxes');first.checked=true;first.dispatchEvent(new Event('change',{bubbles:true}));
    document.getElementById('heritage-next').click();expect(first.checked).toBe(true);expect(first.closest('tr').hidden).toBe(true);
    const status=document.getElementById('heritage-status');status.value='Pending';status.dispatchEvent(new Event('change'));
    expect(document.getElementById('heritage-selection-count').textContent).toContain('1 outside this filter');
    document.getElementById('heritage-select-matching').click();expect(document.querySelectorAll('.boxes:checked').length).toBe(28);
    expect(document.querySelectorAll('tbody tr:not([hidden])').length).toBe(25);
  });
  it('sorts without dropping selected rows or changing column declarations',()=>{
    const first=document.querySelector('.boxes');first.checked=true;
    document.querySelector('thead a').click();expect(first.checked).toBe(true);expect(document.querySelector('th[aria-sort]').getAttribute('aria-sort')).toBe('ascending');
    document.querySelector('thead a').click();expect(document.querySelector('th[aria-sort]').getAttribute('aria-sort')).toBe('descending');
    expect(document.querySelectorAll('tbody tr')).toHaveLength(55);
  });
  it('does not clear hidden selections when deletion is cancelled',()=>{
    const first=document.querySelector('.boxes');first.checked=true;document.getElementById('heritage-next').click();
    vi.spyOn(window,'confirm').mockReturnValue(false);
    const form=document.querySelector('form');const button=document.createElement('button');button.type='submit';button.name='Delete';form.appendChild(button);
    const event=new SubmitEvent('submit',{cancelable:true,submitter:button});form.dispatchEvent(event);
    expect(event.defaultPrevented).toBe(true);expect(first.checked).toBe(true);vi.restoreAllMocks();
  });
});
