/*
 * BestInPlace 3.0.0.alpha (2014)
 *
 * Depends:
 *	best_in_place.js
 *	jquery.purr.js
 */
/*global BestInPlaceEditor */

BestInPlaceEditor.defaults.purrErrorContainer =  "<span class='bip-flash-error'></span>";

jQuery(document).on('best_in_place:error', function (event, request, error) {
    'use strict';
    // Display all error messages from server side validation
    jQuery.each(jQuery.parseJSON(request.responseText), function (index, value) {
        if (typeof value === "object") {value = index + " " + value.toString(); }
        var container = jQuery(BestInPlaceEditor.defaults.purrErrorContainer).html(value);
        container.purr();
    });
});
