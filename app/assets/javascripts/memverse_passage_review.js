/******************************************************************************
 * Display passage for review
 ******************************************************************************/
function mvDisplayPassageForReview( passageRef, verses ) {

    var $new_vs

    // display reference
    $('.passage-title').html( passageRef );

    // clear out existing passage
    $('.passage-text').empty();

    // wrap single verse in array
    if( !($.isArray(verses)) ) { verses = [ verses ]; }

    $.each (verses, function(i, vs) {

        // Check whether verse is due today
        var vsDue = mvDue(vs);

        if (vsDue) {
            $new_vs = buildVerseBlank( vs );
        } else {
            $new_vs = buildVerseText( vs );
        }

        // Display verse on page
        $('.passage-text').append($new_vs);

    });

};

/******************************************************************************
 * Returns a blank input box for verse in passage review
 ******************************************************************************/
function buildVerseBlank( jsonMV ) {

    console.log('Building ' + jsonMV + ' with blanks');

    // Build HTML for each verse
    var $new_vs = $('<div/>').addClass('single-verse-in-passage')

        // add scoring buttons
        .append( $('<div class="passage-rating" />')
            .append('<div class="tool-tip-nav">Rate:</div>')
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
            .append($('<span class="full-text"            />').html( blankifyVerse(jsonMV.text, 50)))
            .append($('<span class="mv-id"                />').text( jsonMV.id       ))
        );

    return $new_vs
}

/******************************************************************************
 * Returns a verse in passage review that is not due
 ******************************************************************************/
function buildVerseText( jsonMV ) {

    console.log('Building ' + jsonMV + ' with text');

    // Build HTML for each verse
    var $new_vs = $('<div/>').addClass('single-verse-in-passage')


        // verse reference
        .append( $('<div class="ref-and-text" />')
            .append($('<span class="versenum superscript" />').text( jsonMV.versenum ))
            .append($('<span class="full-text"            />').text( jsonMV.text     ))
            .append($('<span class="mv-id"                />').text( jsonMV.id       ))
        );

    return $new_vs

}
