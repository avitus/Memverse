var reviewState = {
    // setup
    initialize: function () {
        // Retrieve passages that are due for review
        $.getJSON('passages/due.json', function (data) {

            var items = [];

            // Build list
            $.each(data, function( index, mv ) {
                items.push('<li class="upcoming-verse-ref white2" id="' + mv.id + '">' + mv.ref + '</li>');
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
    $('.passage-title').html( passageRef );
    $('.passage-id').html( passageID );

    // clear out existing passage
    // $('.passage-text').empty();

    // wrap single verse in array
    if( !($.isArray(verses)) ) { verses = [ verses ]; }

    $.each (verses, function(i, vs) {

        // Show full text if verse is not due else build input fields
        $new_vs = mvDue(vs) ? buildVerseBlank( vs ) : buildVerseText( vs ) ;
        // Display verse on page
        $('.passage-text').append($new_vs);

    });

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

    // Word correct ==> next word
    if ( scrub_text( correctWord ) === scrub_text( userGuess ) ) {

        $inputCell.before( "<span>" + correctWord + " </span>" ); // insert the correct word into the verse
        $inputCell.before( $inputCell.nextUntil("input") );       // move subsequent revealed words ahead of input
        mvMirrorNextInput( $inputCell );                          // update the input box

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
