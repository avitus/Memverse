// Progressive enhancements: Rails remains responsible for authentication and persistence.
(function () {
  'use strict';
  document.addEventListener('click', function (event) {
    var toggle = event.target.closest('[data-password-toggle]');
    if (!toggle) return;
    var input = document.getElementById(toggle.getAttribute('data-password-toggle'));
    if (!input) return;
    var show = input.type === 'password';
    input.type = show ? 'text' : 'password';
    toggle.textContent = show ? 'Hide' : 'Show';
    toggle.setAttribute('aria-pressed', String(show));
    toggle.setAttribute('aria-label', (show ? 'Hide ' : 'Show ') + (input.id.indexOf('confirmation') >= 0 ? 'password confirmation' : 'password'));
  });
  document.addEventListener('DOMContentLoaded', function () {
    var form = document.querySelector('.heritage-auth-form');
    if (!form) return;
    var password = form.querySelector('#user_password');
    var confirmation = form.querySelector('#user_password_confirmation');
    function validateConfirmation() {
      if (confirmation) confirmation.setCustomValidity(confirmation.value !== password.value ? 'Passwords do not match.' : '');
    }
    if (confirmation) {
      password.addEventListener('input', validateConfirmation);
      confirmation.addEventListener('input', validateConfirmation);
    }
    var errors = form.querySelector('#error_explanation');
    if (errors) { errors.setAttribute('role', 'alert'); errors.setAttribute('tabindex', '-1'); errors.focus(); }
  });
}());
(function () {
  document.addEventListener('DOMContentLoaded', function () {
    var button = document.getElementById('heritage-theme');
    if (!button) return;
    function apply(theme) {
      document.body.setAttribute('data-theme', theme);
      document.dispatchEvent(new Event('heritage:theme'));
      button.textContent = theme === 'dark' ? 'Light' : 'Dark';
      button.setAttribute('aria-label', theme === 'dark' ? 'Use light appearance' : 'Use dark appearance');
    }
    try { apply(localStorage.getItem('memverse-heritage-theme') || 'light'); } catch (_) { apply('light'); }
    button.addEventListener('click', function () { var theme = document.body.getAttribute('data-theme') === 'dark' ? 'light' : 'dark'; apply(theme); try { localStorage.setItem('memverse-heritage-theme', theme); } catch (_) {} });
  });
}());

// Remote additions must succeed before the action is replaced by a success state.
$(function () {
    if (!document.body.classList.contains('mv-heritage')) return;
    $('.quick-start-add-section').on('ajax:success', '.quick-start-add-button', function (event) {
        var data = event.detail && event.detail[0];
        if (!data || data.msg === 'Error') { $('#heritage-search-message').text('The verse could not be added. Please try again.'); return; }
        $(this).replaceWith($('<span class="verse-added" role="status"/>').text('✓ In your verses'));
        document.dispatchEvent(new Event('heritage:verse-added'));
    }).on('ajax:error', '.quick-start-add-button', function () { $('#heritage-search-message').text('The verse could not be added. Please try again.'); });
});
document.addEventListener('click', function (event) {
    var button = event.target.closest('[data-distribution]');
    if (!button) return;
    document.querySelectorAll('[data-distribution]').forEach(function (item) { item.setAttribute('aria-pressed', String(item === button)); });
    document.querySelectorAll('[data-distribution-panel]').forEach(function (panel) { panel.hidden = panel.getAttribute('data-distribution-panel') !== button.getAttribute('data-distribution'); });
});
document.addEventListener('input', function (event) {
    if (event.target.id !== 'heritage-chapter-search') return;
    var query = event.target.value.toLowerCase();
    document.querySelectorAll('#heritage-chapters tbody tr').forEach(function (row) { row.hidden = row.textContent.toLowerCase().indexOf(query) < 0; });
});

$(function () {
  $('#heritage-reset-schedule').on('click', function (event) {
    event.preventDefault();
    if (!window.confirm('Reset your review schedule?')) return false;
    var link = $(this);
    $.getJSON(link.attr('href')).done(function () { window.location.reload(); }).fail(function () { link.after('<p role="alert">Your schedule could not be reset. Please try again.</p>'); });
    return false;
  });
});

// Suggested passages use the existing search and never add verses automatically.
document.addEventListener('click', function (event) {
  var suggestion = event.target.closest('[data-verse-suggestion]');
  var search = document.getElementById('js_flex-verse-search');
  if (!suggestion || !search) return;
  search.value = suggestion.getAttribute('data-verse-suggestion');
  flexversesearch(search.value);
  search.focus();
});

// The public Scripture exercise is local practice; it never saves account progress.
document.addEventListener('DOMContentLoaded', function () {
  var exercise = document.querySelector('[data-demo-exercise]');
  if (!exercise) return;
  var answer = document.getElementById('heritage-demo-answer');
  var status = document.querySelector('[data-demo-status]');
  var reveal = document.querySelector('[data-demo-reveal]');
  var next = document.querySelector('[data-demo-continue]');
  var shown = false;
  document.querySelectorAll('[data-demo-start]').forEach(function (button) {
    button.addEventListener('click', function (event) {
      event.preventDefault();
      document.querySelector('[data-demo-reading]').hidden = true;
      exercise.hidden = false;
      answer.focus();
    });
  });
  answer.addEventListener('input', function () {
    shown = false;
    reveal.textContent = 'Reveal the word';
    var correct = answer.value.trim().toLowerCase() === 'shepherd';
    status.textContent = correct ? 'Correct. You recalled the word.' : 'Recall the missing word. Reveal it if needed.';
    next.hidden = !correct;
  });
  reveal.addEventListener('click', function () {
    shown = !shown;
    answer.value = shown ? 'shepherd' : '';
    reveal.textContent = shown ? 'Hide the word' : 'Reveal the word';
    status.textContent = shown ? 'Read the word, then recall it again.' : 'Recall the missing word. Reveal it if needed.';
    next.hidden = true;
    answer.focus();
  });
});
