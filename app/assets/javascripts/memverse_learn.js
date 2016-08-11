/******************************************************************************
 * Functionality for /learn page
 ******************************************************************************/
var practiceState = {

    // verse being learned
    ref:      null,
    fullText: null,
    mnemonic: null,
    mvId:     null,

    // verses in practice queue
    queued_verses: 0,

    // in memory queue
    queue: [],

    // current level
    level: 0,

    // add verse to the in-memory queue
    addToQueue: function ( $Verse ) {

        var queueVerse = {
            mvId        : $Verse.find(".mv-id").html(),
            ref         : $Verse.find(".ref").html(),
            fullText    : $Verse.find(".full-text").html(),
            mnemonic    : $Verse.find(".mnemonic").html()
        }

        this.queue.push( queueVerse );

        if (this.queued_verses == 0) {   //j no verses queued up for learning
            this.nextVerse( );
            this.queued_verses += 1;
        }

        this.queued_verses += 1;

        this.updateControls();
    },

    // remove verse from the in-memory queue
    removeFromQueue: function ( mvId ) {

        this.queue = $.grep( this.queue, function( mv ) { return mv.mvId != mvId; });
        this.queued_verses -= 1;
        this.updateControls();

    },

    // update status of current verse
    startReview: function () {
        // TODO - at the end of the learning session verse should be moved to review
    },

    // get next verse
    nextVerse: function () {

        var replacementVerse = this.queue.shift();    // remove first verse from queue
        this.queued_verses -= 1;                      // update queue count

        this.level    = 0;
        this.fullText = replacementVerse.fullText;
        this.ref      = replacementVerse.ref;
        this.mnemonic = replacementVerse.mnemonic;
        this.mvId     = replacementVerse.mvId;

        $(".verse-ref                 ").html( this.ref );
        $(".level-num                 ").html( "0" );
        $(".verse-learning .mnemonic  ").html( this.mnemonic );
        // $(".blankified                ").html( blankifyVerse( this.fullText, this.level * 10 ) );

        this.updateControls();

    },

    // move verse to next level of difficulty
    levelUp: function () {

        if ( this.level < 10 ) {
            this.level += 1;
        }

        this.updateControls();

    },

    // move verse to previous level of difficulty
    levelDown: function () {

        if ( this.level > 0 ) {
            this.level -= 1;
        }

        this.updateControls();

    },

    updateControls: function () {

        $(".level-num ").html( this.level );
        $(".blankified").html( blankifyVerse( this.fullText, this.level * 10 ) );
        $("input.blank-word:first").focus();

        if ( this.level >= 10) {
            $(".inc-level").css('visibility', 'hidden');
            $(".dec-level").css('visibility', 'visible');
        }

        else if ( this.level <= 0 ) {
            $(".inc-level").css('visibility', 'visible');
            $(".dec-level").css('visibility', 'hidden');
        }

        else {
            $(".inc-level").css('visibility', 'visible');
            $(".dec-level").css('visibility', 'visible');
        }

        if ( this.queued_verses === 0 ) {
            $(".cur-level").css('visibility', 'hidden');
            $(".nxt-verse").css('visibility', 'hidden');
        } else if ( this.queued_verses === 1 ) {
            $(".cur-level").css('visibility', 'visible');
            $(".nxt-verse").css('visibility', 'hidden');
        } else {
            $(".cur-level").css('visibility', 'visible');
            $(".nxt-verse").css('visibility', 'visible');
        }

    }

};

/******************************************************************************
 * Display compact list of verse references
 * Input: single verse OR array of verses
 ******************************************************************************/
function displayMvSearchResultsFn( verses ) {

    if (!verses) return;  // nothing to display

    $(".mv-search-results-compact #actions a, .mv-search-results-compact div.scrollable, .mv-search-results-compact").show();

    // wrap single verse in array
    if( !($.isArray(verses)) ) {
        verses = [ verses ];
    }

    $.each (verses, function(i, vs) {

        // We need to group search results to enable scroll
        if (i % 7 == 0) {
            // Start new group
            var $new_vs_group = $('<div/>').addClass('search-result-group');
            $('.items').append($new_vs_group);
        }

        // Show start of verse
        var shortText = jQuery.trim(vs.text).substring(0, 35).split(" ").slice(0, -1).join(" ") + "...";

        // Build HTML for each verse
        var $new_vs = $('<div/>').addClass('item')

            // verse reference
            .append( $('<div class="ref-and-details" />')
                .append($('<h4 class="ref"         />').text( vs.ref      ))
                .append($('<p  class="first-words" />').text( shortText   ))
                .append($('<p  class="full-text"   />').text( vs.text     ))
                .append($('<p  class="mnemonic"    />').text( vs.mnemonic ))
                .append($('<p  class="mv-id"       />').text( vs.id       ))
            )

            // add button
            .append('<div class="select-verse-button"><a href="#" class="compact-add-button"></a></div>');

        // Display verse on page
        $('.search-result-group').filter(':last').append($new_vs);
    });
};

