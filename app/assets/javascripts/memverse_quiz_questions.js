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