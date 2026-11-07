var reviewState = {
    // setup
    initialize: function () {
        // Retrieve passages that are due for review
        $.getJSON('passages/due.json', function (data) {

            var items = [];

            // Build list
            $.each(data, function( index, mv ) {
                var item = $('<li/>', { 'class': 'upcoming-verse-ref white2', id: mv.id });
                if ($('.heritage-passage-picker').length) {
                    $('<button/>', { type: 'button', text: mv.ref }).appendTo(item);
                } else {
                    item.text(mv.ref);
                }
                items.push(item[0].outerHTML);
            });

            // Add entire list
            $('<ul/>', { 'class': 'passage-list', html: items.join('') }).appendTo('.upcoming-passages');

            // Load first passage
            reviewState.autoAdvancePassage();

        });

    },

    selectPassage: function ( passageRef, passageID ) {
        // retrieve memory verses for passage
        $.getJSON('passages/' + passageID + '/memverses.json', function (data) {
            // display passage
            mvDisplayPassageForReview( passageRef, passageID, data )
        });
    },

    clearCurrentPassage: function () {
        // check whether user has completed the review of the passage
        var passageNotReviewed = $(".due-mv").length;
        var passageID          = $(".passage-id").html();

        if (passageID) {
            if (passageNotReviewed) {
                $('.passage-list #' + passageID).appendTo('.passage-list').fadeIn(); // show passage again at end of list
            } else {
                $('.passage-list #' + passageID).remove(); // remove from upcoming passages
            }
        }

        $(".passage-text").empty();
        $(".passage-title").empty();
        $(".heritage-ratings").remove();
    },

    autoAdvancePassage: function ( ) {

        var $nextPassage  = [];

        reviewState.clearCurrentPassage();  // Clear current passage

        // Select next passage from top of list
        $nextPassage = $( ".upcoming-passages" ).find(".upcoming-verse-ref").first();

        if ($nextPassage.length) {
            $nextPassage.fadeOut('slow');
            reviewState.selectPassage( $nextPassage.text(), $nextPassage.attr('id') );
        } else {
            log_progress( memverseUserID );
            window.location="./progress";
        }

        return false;  // prevent default behavior
    },

    gotoNextVerseDue: function ( $currentVerse ) {

        var $nextDue      = $currentVerse.nextAll(".due-mv").first();
        var $firstSkipped

        // If there are more verses due in the passage
        if ($nextDue.length) {
            // Scroll to next verse
            reviewState.scrollToVerse( $nextDue );

        // Check for earlier verses in passage that were skipped
        } else if ( $currentVerse.siblings(".due-mv").length ) {
            // find first skipped verse
            $firstSkipped = $currentVerse.siblings(".due-mv").first();
            // Scroll to prior verse
            reviewState.scrollToVerse( $firstSkipped );

        // Get next passage if no more verses on this one
        } else {

            reviewState.autoAdvancePassage();

        }
    },

    scrollToVerse: function ( $verse ) {
        // Scroll to next verse
        $('html').scrollTo($verse, { easing: 'easeInOutCubic', duration: 1500, offset: -250 } );
        // advance cursor to first word of next verse
        $verse.find('.blank-word').first().focus();
    }
};

/******************************************************************************
 * Display passage for review
 ******************************************************************************/
function mvDisplayPassageForReview( passageRef, passageID, verses ) {

    var $new_vs

    // display reference
    $('.passage-title').text( passageRef );
    $('.passage-id').html( passageID );

    // clear out existing passage
    // $('.passage-text').empty();

    // wrap single verse in array
    if( !($.isArray(verses)) ) { verses = [ verses ]; }

    $('.heritage-passage-kicker').text(/^Psalms? /.test(passageRef) ? 'The Psalms' : 'Holy Bible');
    $('.heritage-passage-version').text(verses.length ? verses[0].tl : '');

    $.each (verses, function(i, vs) {

        // Show full text if verse is not due else build input fields
        $new_vs = mvDue(vs) ? buildVerseBlank( vs ) : buildVerseText( vs ) ;
        // Display verse on page
        $('.passage-text').append($new_vs);

    });

    if (document.body.classList.contains('mv-heritage')) mvHeritagePrepareRatings();

    // Scroll to first verse due
    reviewState.scrollToVerse( $('.passage-text').find('.due-mv').first() );

};

/******************************************************************************
 * Returns a blank input box for verse in passage review
 ******************************************************************************/
function buildVerseBlank( jsonMV ) {

    var testInterval    = jsonMV.test_interval;
    var blankPercentage = testInterval * 5 + 25;

    // Build HTML for each verse
    var $new_vs = $('<div/>').addClass('single-verse-in-passage due-mv')

        // add scoring buttons
        .append( $('<div class="passage-rating" />')
            .append('<div class="tool-tip-nav">Rate:</div>')
            .append($('<div class="mv-id" />').text( jsonMV.id ))
            .append( $('<div class="score-test-buttons" />')
                .append( $('<span class="submit" q="1" />').text(1))
                .append( $('<span class="submit" q="2" />').text(2))
                .append( $('<span class="submit" q="3" />').text(3))
                .append( $('<span class="submit" q="4" />').text(4))
                .append( $('<span class="submit" q="5" />').text(5))
            )
        )

        // verse reference
        .append( $('<div class="ref-and-text" />')
            .append($('<span class="versenum superscript"/>').text( jsonMV.versenum ))
            .append($('<span class="full-text"           />').html( blankifyVerse(jsonMV.text, blankPercentage)))
            .append($('<span class="mv-id"               />').text( jsonMV.id       ))
        );

    return $new_vs
}

/******************************************************************************
 * Returns a verse in passage review that is not due
 ******************************************************************************/
function buildVerseText( jsonMV ) {

    // Build HTML for each verse
    var $new_vs = $('<div/>').addClass('single-verse-in-passage')

        // verse reference
        .append( $('<div class="ref-and-text" />')
            .append($('<span class="versenum superscript" />').text( jsonMV.versenum ))
            .append($('<span class="full-text"            />').text( jsonMV.text     ))
        );

    return $new_vs

}

/******************************************************************************
 * Handle user input for Passage Review
 *
 * TODO: Since iOS does not allow focus to be moved around the DOM, we have to
 *       keep focus on a single input box and slide the verse around instead.
 *
 ******************************************************************************/
function mvMirrorNextInput( $inputCell ) {

    if ( $inputCell.next().is("input") ) {

        // to support iOS, we update the current input to mirror the next input
        $inputCell.attr("name", $inputCell.next().attr("name"));
        $inputCell.css ("width", $inputCell.next().css("width"));
        $inputCell.val( $inputCell.next().val() );

        // and then we remove the next input
        $inputCell.next().remove();

    } else {

        // remove this input... because there are no more inputs
        $inputCell.remove();
    }
}

function mvPassageReviewHandleInput( $inputCell, correctWord, userGuess, e ) {
    var heritageVerse = $inputCell.closest(".single-verse-in-passage");

    // Word correct ==> next word (using flexible matching)
    // Note: We already checked for match in the keyup handler, so this check is redundant
    // but kept for compatibility with arrow key handling
    if ( flexibleTextMatch( correctWord, userGuess ) ) {

        // Calculate the width the span will need and preserve input width to prevent layout shift
        var currentWidth = $inputCell.width();
        var $span = $("<span>").text(correctWord + " ").css({
            'display': 'inline-block',
            'min-width': currentWidth + 'px'
        });

        $inputCell.before( $span );                               // insert the correct word with preserved width
        $inputCell.before( $inputCell.nextUntil("input") );       // move subsequent revealed words ahead of input
        mvMirrorNextInput( $inputCell );                          // update the input box
        if (document.body.classList.contains("mv-heritage")) {
            if (!heritageVerse.find("input.blank-word").length) heritageVerse.nextAll().find("input.blank-word").first().focus();
            if (!$(".passage-text input.blank-word").length) $(".heritage-ratings").prop("hidden", false);
        }

    }

    // check for down arrow keypress
    else if ( e.keyCode === 40 ) {
        // reveal current word
        $inputCell.val( correctWord ).animate({ color: '#FFD' }, 1100, 'easeInExpo', function() {
            $inputCell.val('');
            $inputCell.css({color:'#444'}); // same color as .assistance
        });;
    }

    // check for up arrow keypress
    else if ( e.keyCode === 38 ) {
        // reveal entire verse
        $inputCell.parent().find("input").each( function() {
            $(this).val( this.name ).animate({ color: '#FFD' }, 2000, 'easeInExpo', function() {
                $(this).val('');
                $(this).css({color:'#444'}); // same color as .assistance
            });
        });
    }

}

// Keep scoring below the complete passage. A rating changes state only after a successful save.
function mvHeritagePrepareRatings() {
    var panel = $('<section class="heritage-ratings" hidden><h2>How did you recall it?</h2><p role="status" class="heritage-review-status"></p></section>');
    $('.passage-text .due-mv').each(function () {
        var verse = $(this), id = verse.find('.mv-id').first().text();
        var row = $('<div class="heritage-rating-row"/>').append($('<span/>').text('Verse ' + verse.find('.versenum').text()));
        var buttons = $('<div class="score-test-buttons"/>');
        [1,2,3,4,5].forEach(function (quality) {
            $('<button type="button"/>').text(quality).attr('aria-label', 'Rate verse ' + verse.find('.versenum').text() + ': ' + quality + ' of 5').on('click', function () {
                buttons.find('button').prop('disabled', true);
                $.getJSON('/mark_test_quick', {mv:id,q:quality}).done(function (data) {
                    if (data.msg) panel.find('.heritage-review-status').text(data.msg);
                    verse.removeClass('due-mv');
                    row.empty().append($('<span/>').text('Verse ' + verse.find('.versenum').text() + ' · Rated ' + quality + '/5'));
                    panel.find('.heritage-next-passage').prop('disabled', $('.passage-text .due-mv').length > 0);
                }).fail(function () { buttons.find('button').prop('disabled', false); panel.find('.heritage-review-status').text('Your rating could not be saved. Please try again.'); });
            }).appendTo(buttons);
        });
        row.append(buttons).appendTo(panel);
    });
    $('<button type="button" class="heritage-next-passage" disabled>Next passage →</button>').on('click',function(){reviewState.autoAdvancePassage();}).appendTo(panel);
    $('.passage-entry').append(panel);
    if (!$('.passage-text input.blank-word').length) panel.prop('hidden', false);
    panel.find('.heritage-next-passage').prop('disabled', $('.passage-text .due-mv').length > 0);
}
