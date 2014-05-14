/******************************************************************************
 * Display related quiz questions
 * Input: single question OR array of questions
 ******************************************************************************/
function displayRelatedQuestionsSearchResultsFn( quiz_questions ) {

    $('.related-quiz-questions').empty(); // Clear prior results

    if (typeof quiz_questions === 'undefined' || quiz_questions === null || quiz_questions.length === 0) return;

    $('.related-quiz-questions').append( $('<h5/>').text("Related Questions") );

    $.each (quiz_questions, function(i, qq) {

        // Build HTML for each verse
        var $new_qq = $('<div/>').addClass('item')

            // verse reference
            .append( $('<div class="related-q" />')
                .append($('<span class="difficulty"   />').text( qq.perc_correct + ": " ))
                .append($('<span class="mcq-question" />').text( qq.mc_question  )) // re-using class from learn page
            );

        // Display verse on page
        $('.related-quiz-questions').filter(':last').append($new_qq);
    });
};

/******************************************************************************
 * Display related quiz questions
 * Input: single question OR array of questions
 * TODO: ===> This is almost an exact duplicate of function above
 *            It is only used for the quiz question approval page
 ******************************************************************************/
function displayRelatedQuestionsSearchResultsForApprovalFn( quiz_questions ) {

    $(this).prev('.related-quiz-questions').empty(); // Clear prior results

    if (typeof quiz_questions === 'undefined' || quiz_questions === null || quiz_questions.length === 0) return;

    $('.related-quiz-questions').append( $('<h5/>').text("Related Questions") );

    $.each (quiz_questions, function(i, qq) {

        // Build HTML for each verse
        var $new_qq = $('<div/>').addClass('item')

            // verse reference
            .append( $('<div class="related-q" />')
                .append($('<span class="difficulty"   />').text( qq.perc_correct + ": " ))
                .append($('<span class="mcq-question" />').text( qq.mc_question  )) // re-using class from learn page
            );

        // Display verse on page
        $(this).prev('.related-quiz-questions').filter(':last').append($new_qq);
    });
};

/******************************************************************************
 * Display full list of verses
 * Input: single verse OR array of verses
 * TODO: ===> This is almost an exact duplicate of function in memverse_live_quiz.js
 *            It is only used for the quiz question approval page
 ******************************************************************************/
function displayMultiTranslationSearchResultsForApprovalFn( verses ) {

    $(this).prev('.supporting-ref-display').empty(); // Clear prior results

    if (!verses) return;  // nothing to display

    // wrap single verse in array
    if( !($.isArray(verses)) ) {
        verses = [ verses ];
    }

    $.each (verses, function(i, vs) {

        // Build HTML for each verse
        var $new_vs = $('<div/>').addClass('item')

            // verse reference
            .append( $('<div class="ref-and-details" />')
                .append($('<h5 class="ref"         />').text( vs.tl   ))
                .append($('<p  class="first-words" />').text( vs.text )) // re-using class from learn page
            );

        // Display verse on page
        $(this).prev('.supporting-ref-display').filter(':last').append($new_vs);
    });
};