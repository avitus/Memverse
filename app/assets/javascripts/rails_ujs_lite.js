// Lightweight Rails UJS replacement for data-remote and data-method links
// This handles the basic functionality needed by Memverse without requiring the full jquery_ujs

$(document).ready(function() {
  // Handle data-remote links
  $(document).on('click', 'a[data-remote="true"], a[remote="true"]', function(e) {
    e.preventDefault();
    
    var link = $(this);
    var url = link.attr('href');
    var method = (link.data('method') || link.attr('method') || 'get').toUpperCase();
    var format = 'json';
    
    // Extract format from URL if present
    var formatMatch = url.match(/\.(\w+)$/);
    if (formatMatch) {
      format = formatMatch[1];
    }
    
    // Check for confirmation
    var confirmMessage = link.data('confirm');
    if (confirmMessage && !confirm(confirmMessage)) {
      return false;
    }
    
    // Determine dataType based on format
    var dataType = format;
    if (format === 'js') {
      dataType = 'script';
    }
    
    $.ajax({
      url: url,
      type: method,
      dataType: dataType,
      headers: {
        'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content'),
        'Accept': format === 'json' ? 'application/json' : '*/*'
      },
      beforeSend: function(xhr, settings) {
        // Trigger event for compatibility
        link.trigger('ajax:before', [xhr, settings]);
      },
      success: function(data, status, xhr) {
        // Handle JSON responses
        if (format === 'json' && typeof data === 'object') {
          // Check for specific handlers
          if (link.attr('id') === 'ajax_add' && data.response) {
            // Handle verse add response
            alert(data.response);
            if (data.response.indexOf('successfully') !== -1) {
              link.hide();
            }
          } else if (url.indexOf('toggle_mv_status') !== -1 && data.new_status) {
            // Handle memverse status toggle
            link.text(data.new_status);
          } else {
            // Trigger generic success event
            link.trigger('ajax:success', [data, status, xhr]);
          }
        } else {
          // For non-JSON responses, trigger the event
          link.trigger('ajax:success', [data, status, xhr]);
        }
      },
      error: function(xhr, status, error) {
        link.trigger('ajax:error', [xhr, status, error]);
        
        // Show error if no custom handler catches it
        if (!link.data('suppress-error')) {
          var message = 'An error occurred';
          try {
            var json = JSON.parse(xhr.responseText);
            if (json.error) message = json.error;
          } catch(e) {}
          console.error('AJAX Error:', error, xhr.responseText);
        }
      },
      complete: function(xhr, status) {
        link.trigger('ajax:complete', [xhr, status]);
      }
    });
  });
  
  // Handle data-method links (non-remote)
  $(document).on('click', 'a[data-method]:not([data-remote]):not([remote])', function(e) {
    e.preventDefault();
    
    var link = $(this);
    var href = link.attr('href');
    var method = link.data('method');
    var csrfToken = $('meta[name="csrf-token"]').attr('content');
    var csrfParam = $('meta[name="csrf-param"]').attr('content') || 'authenticity_token';
    
    // Check for confirmation
    var confirmMessage = link.data('confirm');
    if (confirmMessage && !confirm(confirmMessage)) {
      return false;
    }
    
    // Create and submit form
    var form = $('<form>', {
      method: 'POST',
      action: href,
      style: 'display:none'
    });
    
    if (method !== 'post') {
      form.append($('<input>', {
        type: 'hidden',
        name: '_method',
        value: method
      }));
    }
    
    form.append($('<input>', {
      type: 'hidden',
      name: csrfParam,
      value: csrfToken
    }));
    
    form.appendTo('body').submit();
  });
});