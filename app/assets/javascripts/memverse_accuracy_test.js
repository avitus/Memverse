var accTestState = {

    currentMvID: null,
    currentRef: null,
    currentText: null,
    accuracy: null,

    // setup
    initialize: function ( user_accuracy ) {

        accTestState.currentRef  = "";
        accTestState.currentText = "";
        accTestState.accuracy = user_accuracy;
        accTestState.getMV();

    },

    getMV: function () {

        // Retrieve a verse for testing
        $.getJSON('accuracy_test_next.json', function (data) {

            // Prior verse text if available
            var priorVerseText, priorVerseRef

            if ( data.prior_mv && data.prior_mv !== "null" && data.prior_mv !== "undefined" ) {
                priorVerseText = data.prior_mv.text;
                priorVerseRef  = data.prior_mv.ref;
            }
            else {
                priorVerseText = "";
                priorVerseRef  = "";
            }

            accTestState.currentText = data.mv.text;
            accTestState.currentRef  = data.mv.ref;
            accTestState.currentMvID = data.mv.id;

            // Clear previous verse
            $('#answer').val('').focus();         // Clear entry box
            $('.diff-calc .original').empty();
            $('.diff-calc .changed').empty();
            $('.diff-calc .diff').clone().prependTo(".prior-questions");
            $('.diff-calc .diff').empty();
            $('.prior-verse-text').empty();

            // Insert new verse
            $('.verse-ref.current').html( accTestState.currentRef  );   // Show verse reference
            $('.verse-ref.prior'  ).html( priorVerseRef            );   // Show verse reference
            $('.changed'          ).html( accTestState.currentText );   // Insert correct text
            $('.prior-verse-text' ).html( priorVerseText           );   // Text for prior verse
            $('.q-num').text( function (i,qNum) { return parseInt(qNum)+1;} ) ; // Increment question number
        });

    },

    scoreRecitation: function ( user_answer, correct_answer ) {

        var score;

        // Convert to lowercase; remove anything that is not a-z or Korean Hangul and remove extra spaces
        // Do I need to use unescape because of quotation marks? Time will tell...
        user    = $.trim(    user_answer.toLowerCase().replace(/[^a-z0-9\uAC00-\uD7A3 ]|\s-|\s—/g, '').replace(/\s+/g, " ") );
        correct = $.trim( correct_answer.toLowerCase().replace(/[^a-z0-9\uAC00-\uD7A3 ]|\s-|\s—/g, '').replace(/\s+/g, " ") );

        if (user == "") {
            alert('Please recite the verse. You clicked "Submit" without any words in the box.')
            return false;
        }

        user_words  = user.split(" ");
        right_words = correct.split(" ");

        score = 10 - (calculate_levenshtein_distance(right_words, user_words));

        if (score < 0) {score = 0;} // Prevents score from being less than 0.

        accTestState.showScore( score );

        return score;

    },

    showScore: function ( score) {

        var $currentDiff = $(".diff-calc > .diff:first");

        $currentDiff.prepend( $('<span class="acc-score"/>' ).text('[ ' + score + ' ] ') );

        // var msg;
        // var $feedback;
        // var answerBk, answerCh, answerVs;

        // switch (userScore) {
        //     case 10:
        //         msg = "Perfect!";
        //         break;
        //     case 5:
        //         msg = "Correct book and chapter.";
        //         break;
        //     case 1:
        //         msg = "Correct book.";
        //         break;
        //     case 0:
        //         msg = "Incorrect.";
        //         break;
        //     default:
        //         msg = "Something weird happened!";
        // }

        // // answerRef will be false if user did not enter a parseable single verse
        // // Override null values
        // answerBk = (answerRef == false ) ? '- ' : answerRef.bk;
        // answerCh = (answerRef == false ) ? '-'  : answerRef.ch;
        // answerVs = (answerRef == false ) ? '-'  : answerRef.vs;

        // $feedback = $('<div/>').addClass('prior-feedback')
        //     .append( $('<span class="prior-question"/>').text( correctRef.bk + ' ' + correctRef.ch + ":" + correctRef.vs ) )
        //     .append( $('<span class="divider"       />').text( ' - ' ) )
        //     .append( $('<span class="prior-answer"  />').text( '[' + answerBk + ' ' + answerCh + ":" + answerVs + '] ' ) )
        //     .append( $('<span class="prior-feedback"/>').text( msg   ) );

        // $("#past-questions").prepend( $feedback );

    },

    updateAccuracy: function ( questionScore ) {

        var newAccuracy;

        newAccuracy = Math.ceil( accTestState.accuracy * 0.90 + questionScore );
        accTestState.accuracy = newAccuracy;
        this.saveAccuracy( newAccuracy );   // save to server
        return newAccuracy;
    },

    saveAccuracy: function ( accuracy ) {
        $.post('save_accuracy/' + accuracy + '.json', function(data) {
            // Todo: alert user if failure to save score
        });
    }

};
