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

    $('.passage-text').find('.blank-word').first().focus();

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
            .append($('<span class="versenum superscript" />').text( jsonMV.versenum ))
            .append($('<span class="full-text"            />').html( blankifyVerse(jsonMV.text, blankPercentage)))
            .append($('<span class="mv-id"                />').text( jsonMV.id       ))
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
