/******************************************************************************
 * Display passage for review
 ******************************************************************************/
function mvDisplayPassageForReview( passageRef, verses ) {

    // display reference
    $('.passage-title').html( passageRef );

    // clear out existing passage
    $('.passage-text').empty();

    // wrap single verse in array
    if( !($.isArray(verses)) ) { verses = [ verses ]; }

    $.each (verses, function(i, vs) {

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
                .append($('<span class="versenum superscript" />').text( vs.versenum ))
                .append($('<span class="full-text"            />').text( vs.text     ))
                .append($('<span class="mv-id"                />').text( vs.id       ))
            );

        // Display verse on page
        $('.passage-text').append($new_vs);

    });

};



