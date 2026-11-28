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
        if (reviewState.passageRequest) reviewState.passageRequest.abort();
        var options = $('.heritage-passage-heading').length ? { passage_review: 1 } : {};
        reviewState.passageRequest = $.getJSON('passages/' + passageID + '/memverses.json', options, function (data) {
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
        $('.heritage-review-footer').prop('hidden', true);
        $('.heritage-review-status').text('');
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

        var verses = $('.passage-text .single-verse-in-passage');
        var later = verses.slice(verses.index($currentVerse) + 1).filter('.due-mv');
        var next = later.length ? later.first() : verses.filter('.due-mv').first();
        if (next.length) reviewState.scrollToVerse(next);
        else if ($('.heritage-review-footer').length) $('.heritage-next-passage')[0].focus({ preventScroll: true });
        else reviewState.autoAdvancePassage();
    },

    scrollToVerse: function ($verse) {
        var verse = $verse[0];
        if (!verse) return;
        var control = verse.querySelector('.blank-word, .verse-rating:not([hidden]) button:not([hidden])');
        var target = control || verse;
        if (control) control.focus({ preventScroll: true });
        var bounds = target.getBoundingClientRect();
        var viewport = window.visualViewport;
        var height = viewport ? viewport.height : window.innerHeight;
        var delta = bounds.top + bounds.height / 2 - (viewport ? viewport.offsetTop : 0) - height / 2;
        if (Math.abs(delta) > height * .08) {
            window.scrollBy({ top: delta, behavior: window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'instant' : 'smooth' });
        }
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

    if ($('.heritage-passage-heading').length) {
        mvDisplayHeritagePassage(passageRef, verses);
        reviewState.scrollToVerse($('.passage-text .due-mv').first());
        return;
    }

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
            .append($('<span class="full-text"           />').html( blankifyVerse(jsonMV.text, blankPercentage, true)))
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
function mvRevealPassageWord(input) {
    var slot = input.parentNode;
    var nextSlot = $(slot).nextAll('.passage-blank').first()[0];

    if (!nextSlot) {
        input.remove();
        slot.classList.remove('passage-blank');
        return;
    }

    // Keep the focused input in place for mobile keyboards. Move the intervening
    // text (including its spaces) before it, then reuse it for the next answer.
    var revealed = document.createElement('span');
    revealed.className = 'passage-word';
    revealed.appendChild(slot.firstChild);
    slot.parentNode.insertBefore(revealed, slot);
    while (slot.nextSibling !== nextSlot) {
        slot.parentNode.insertBefore(slot.nextSibling, slot);
    }
    var nextInput = nextSlot.querySelector('input');
    slot.insertBefore(nextSlot.firstChild, input);
    input.name = nextInput.name;
    input.value = nextInput.value;
    if (nextInput.hasAttribute('aria-label')) input.setAttribute('aria-label', nextInput.getAttribute('aria-label'));
    nextSlot.remove();
}

function mvPassageReviewHandleInput( $inputCell, correctWord, userGuess, e ) {
    var heritageVerse = $inputCell.closest(".single-verse-in-passage");

    // Word correct ==> next word (using flexible matching)
    // Note: We already checked for match in the keyup handler, so this check is redundant
    // but kept for compatibility with arrow key handling
    if ( flexibleTextMatch( correctWord, userGuess ) ) {

        mvRevealPassageWord($inputCell[0]);
        if (heritageVerse.hasClass('heritage-review-verse') && !heritageVerse.find('.blank-word').length) {
            heritageVerse.find('.verse-rating').prop('hidden', false);
            mvArrangeMarginRatings();
            reviewState.scrollToVerse(heritageVerse);
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
        $inputCell.closest(".full-text").find("input.blank-word").each( function() {
            $(this).val( this.name ).animate({ color: '#FFD' }, 2000, 'easeInExpo', function() {
                $(this).val('');
                $(this).css({color:'#444'}); // same color as .assistance
            });
        });
    }

}

// Put each control beside its verse ending. Very short verses can finish on
// the same line: share the rail horizontally first, then stack if necessary.
function mvArrangeMarginRatings() {
    var label = document.querySelector('.rating-margin-label');
    if (!label) return;
    var railWidth = label.getBoundingClientRect().width;
    var lastTop = -Infinity, right = 0, bottom = -Infinity;
    $('.verse-rating:not([hidden])').each(function () {
        var anchor = this.parentElement.getBoundingClientRect();
        var width = this.offsetWidth, height = this.offsetHeight;
        var top = anchor.top - height * 0.68, left = 0;
        if (top < bottom + 3) {
            if (right + 4 + width <= railWidth) {
                left = right + 4;
                top = lastTop;
            } else {
                top = bottom + 3;
            }
        }
        this.style.transform = 'translate(' + left + 'px,' + (top - anchor.top) + 'px)';
        right = left + width;
        lastTop = top;
        bottom = Math.max(bottom, top + height);
    });
}

function mvUpdateReviewCount() {
    var total = $('.passage-text .verse-rating').length;
    var remaining = $('.passage-text .due-mv').length;
    $('.heritage-review-count').text(remaining ? (total - remaining) + ' of ' + total + ' verses rated' : 'Passage reviewed.');
    $('.heritage-next-passage').prop('hidden', remaining > 0);
    $('.heritage-review-footer').prop('hidden', false);
    $('.heritage-queue-count').text($('.passage-list li').length - (remaining ? 0 : 1));
}

function mvPassageRating(verse, record) {
    var state = record.rating, number = record.versenum;
    var control = $('<span class="verse-rating"/>');
    var saved = $('<button type="button" class="saved-grade" aria-expanded="false"/>').appendTo(control);
    var scale = $('<span class="rating-options" role="group"/>').attr('aria-label', 'Rate verse ' + number).appendTo(control);
    var labels = ['Forgot', 'Difficult', 'Fair', 'Good', 'Easy'];

    function display(editing) {
        var choosing = editing || !state.quality;
        saved.prop('hidden', choosing).text(state.quality).attr('aria-label', 'Verse ' + number + ', rated ' + state.quality + '. Change rating');
        scale.prop('hidden', !choosing);
        scale.children().each(function () {
            this.setAttribute('aria-pressed', Number(this.value) === state.quality);
        });
        mvArrangeMarginRatings();
    }

    saved.on('click', function () {
        display(true);
        reviewState.scrollToVerse(verse);
        scale.children().eq(state.quality - 1)[0].focus({ preventScroll: true });
    });
    scale.on('keydown', function (event) {
        if (event.key === 'Escape' && state.quality) {
            display(false);
            saved[0].focus({ preventScroll: true });
        }
    });
    labels.forEach(function (label, index) {
        var quality = index + 1;
        $('<button type="button"/>').text(quality).val(quality).attr({
            title: label, 'aria-label': 'Verse ' + number + ', ' + quality + ' of 5, ' + label
        }).appendTo(scale);
    });
    scale.on('click', 'button', function () {
        var previous = state.quality;
        var data = { quality: this.value, previous: previous, attempt: state.attempt, day: state.day };
        scale.children().prop('disabled', true);
        $.ajax({ url: '/review/verses/' + record.id + '/rating', type: 'PATCH', dataType: 'json', data: data })
          .done(function (result) {
            if (!verse[0].isConnected) return;
            state = result.rating;
            verse.removeClass('due-mv');
            display(false);
            mvUpdateReviewCount();
            $('.heritage-review-status').text(result.msg || '');
            if (!previous) reviewState.gotoNextVerseDue(verse);
            else saved[0].focus({ preventScroll: true });
          }).fail(function (xhr) {
            if (!verse[0].isConnected) return;
            var latest = xhr.responseJSON && xhr.responseJSON.rating;
            if (xhr.status === 409 && latest && latest.day === state.day && latest.attempt === state.attempt) {
                state = latest;
                verse.toggleClass('due-mv', !state.quality);
                display(false);
                mvUpdateReviewCount();
            }
            $('.heritage-review-status').text(xhr.status === 409 ? 'This review has changed. Check the current rating or reload the passage.' : 'Your rating could not be saved. Please try again.');
          }).always(function () { scale.children().prop('disabled', false); });
    });
    display(false);
    return $('<span class="verse-end"/>').append(control.prop('hidden', !!verse.find('.blank-word').length));
}

function mvDisplayHeritagePassage(reference, records) {
    var reader = $('.passage-text').empty();
    $('<div class="rating-margin-label">Your rating</div>').appendTo(reader);
    var romans = /^Romans 8:/.test(reference);
    $('.heritage-passage-kicker').text(romans ? 'Paul’s letter to the Romans' : /^Psalms? /.test(reference) ? 'The Psalms' : 'Holy Bible');
    var translation = records.length && records[0].tl;
    $('.heritage-passage-version').text(translation === 'NIV' ? 'New International Version · 1984' : translation || '');
    $('.heritage-niv-credit').prop('hidden', translation !== 'NIV');
    var paragraph;
    records.forEach(function (record, index) {
        // Preserve a continuous reading column, independent of which verses are due.
        if (!index || /^\s*\n/.test(record.text) || (romans && [5, 9].indexOf(record.versenum) !== -1)) {
            paragraph = $('<p class="reading-paragraph"/>').appendTo(reader);
        }
        var due = !record.rating.quality && mvDue(record);
        var verse = $('<span class="single-verse-in-passage heritage-review-verse"/>').toggleClass('due-mv', due);
        var words = $('<span class="full-text"/>').appendTo(verse);
        $('<sup class="versenum"/>').text(record.versenum).appendTo(words);
        if (due) {
            var blanks = $('<span/>').html(blankifyVerse(record.text, record.test_interval * 5 + 25, true)).appendTo(words);
            blanks.find('input').each(function (i) { this.setAttribute('aria-label', 'Verse ' + record.versenum + ', blank ' + (i + 1)); });
        } else {
            words.append(document.createTextNode(record.text));
        }
        if (due || record.rating.quality) verse.append(mvPassageRating(verse, record));
        paragraph.append(verse, ' ');
    });
    mvUpdateReviewCount();
    mvArrangeMarginRatings();
    if (reviewState.marginObserver) reviewState.marginObserver.disconnect();
    reviewState.marginObserver = new ResizeObserver(mvArrangeMarginRatings);
    reviewState.marginObserver.observe(reader[0]);
}
