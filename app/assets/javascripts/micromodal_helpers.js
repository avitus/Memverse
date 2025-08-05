/**
 * MicroModal Helper Functions
 * Replacement for FancyBox functionality
 */

// Initialize MicroModal when document is ready
$(document).ready(function() {
  // Initialize MicroModal
  if (typeof MicroModal !== 'undefined') {
    MicroModal.init({
      onShow: function(modal) {
        console.log('MicroModal opened:', modal.id);
      },
      onClose: function(modal) {
        console.log('MicroModal closed:', modal.id);
      },
      awaitCloseAnimation: true,
      debugMode: false
    });
  }
});

/**
 * Open a video in a modal
 * Replacement for $.fancybox video functionality
 */
function openVideoModal(videoUrl, title) {
  title = title || 'Video';
  
  // Validate and clean the video URL
  if (!videoUrl || videoUrl.trim() === '') {
    console.error('Invalid video URL provided to openVideoModal');
    return;
  }
  
  // Ensure the URL is properly formatted
  videoUrl = videoUrl.trim();
  
  // Log for debugging
  console.log('Opening video modal with URL:', videoUrl);
  
  // Create modal HTML
  var modalId = 'video-modal-' + Date.now();
  var modalHtml = 
    '<div class="micromodal-slide" id="' + modalId + '" aria-hidden="true">' +
      '<div class="modal__overlay" tabindex="-1" data-micromodal-close>' +
        '<div class="modal__container modal__container--video" role="dialog" aria-modal="true" aria-labelledby="' + modalId + '-title">' +
          '<button class="modal__close" aria-label="Close modal" data-micromodal-close>&times;</button>' +
          '<div class="modal__video-container">' +
            '<iframe src="' + encodeURI(videoUrl) + '" frameborder="0" allowfullscreen allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"></iframe>' +
          '</div>' +
        '</div>' +
      '</div>' +
    '</div>';
  
  // Add modal to body
  $('body').append(modalHtml);
  
  // Open modal
  MicroModal.show(modalId);
  
  // Clean up after closing
  $(document).on('click', '[data-micromodal-close]', function() {
    // Stop video playback by removing the iframe
    $('#' + modalId + ' iframe').attr('src', '');
    setTimeout(function() {
      $('#' + modalId).remove();
    }, 300);
  });
}

/**
 * Open content in a modal
 * Replacement for $.fancybox inline content functionality
 */
function openContentModal(content, title, options) {
  options = options || {};
  title = title || '';
  
  var modalId = 'content-modal-' + Date.now();
  var modalHtml = 
    '<div class="micromodal-slide" id="' + modalId + '" aria-hidden="true">' +
      '<div class="modal__overlay" tabindex="-1" data-micromodal-close>' +
        '<div class="modal__container" role="dialog" aria-modal="true" aria-labelledby="' + modalId + '-title">' +
          '<button class="modal__close" aria-label="Close modal" data-micromodal-close>&times;</button>' +
          (title ? '<header class="modal__header"><h2 class="modal__title" id="' + modalId + '-title">' + title + '</h2></header>' : '') +
          '<main class="modal__content">' + content + '</main>' +
        '</div>' +
      '</div>' +
    '</div>';
  
  // Add modal to body
  $('body').append(modalHtml);
  
  // Open modal
  MicroModal.show(modalId);
  
  // Clean up after closing
  setTimeout(function() {
    $(document).on('click', '[data-micromodal-close]', function() {
      setTimeout(function() {
        $('#' + modalId).remove();
      }, 300);
    });
  }, 100);
}

/**
 * Close any open modals
 * Replacement for $.fancybox.close()
 */
function closeModal() {
  MicroModal.close();
}

/**
 * jQuery plugin to maintain fancybox-like API for easier migration
 */
$.fn.microModal = function(options) {
  options = options || {};
  
  return this.each(function() {
    var $this = $(this);
    var href = $this.attr('href');
    var content = $this.html();
    
    $this.on('click', function(e) {
      e.preventDefault();
      
      if (href && (href.indexOf('youtube.com') > -1 || href.indexOf('vimeo.com') > -1)) {
        // Video modal
        openVideoModal(href, options.title);
      } else if (href && href.charAt(0) === '#') {
        // Inline content modal
        var inlineContent = $(href).html();
        openContentModal(inlineContent, options.title, options);
      } else {
        // Content modal
        openContentModal(content, options.title, options);
      }
    });
  });
};

// Global functions to maintain compatibility with existing fancybox calls
window.openVideoModal = openVideoModal;
window.openContentModal = openContentModal;
window.closeModal = closeModal;