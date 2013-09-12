var accTestState = {

    currentMvID: null,
    currentRef: null,
    currentText: null,
    accuracy: null,

    // setup
    initialize: function ( accuracy ) {

        this.currentRef = "";
        this.accuracy = accuracy;
        accTestState.getMV();

    },

    getMV: function () {

        // Retrieve a reference for testing
        $.getJSON('accuracy_test_next.json', function (data) {

            currentText = data.mv.text;
            currentRef  = data.mv.ref;
            currentMvID = data.mv.id;

            $('#answer').val('').focus();         // Clear entry box
            $('.verse-ref').html( currentRef );   // Show verse reference
            $('.original').html( currentText );   // Insert correct text
            $('.q-num').text( function (i,qNum) { return parseInt(qNum)+1;} ) ; // Increment question number
        });

    },


    // perfect                = 10 points
    // correct book & chapter = 5 points
    // correct book           = 1 point
    scoreRef: function ( user_answer ) {

        var answerRef  = parseVerseRef( user_answer );
        var correctRef = parseVerseRef( currentRef );
        var userScore  = 0;

        if ( answerRef.bk === correctRef.bk ) {
            userScore += 1;
            if ( answerRef.ch === correctRef.ch ) {
                userScore += 4;
                if ( answerRef.vs === correctRef.vs ) {
                    userScore += 5;
                }
            }
        }

        this.recordScore( userScore );
        this.giveFeedback( answerRef, correctRef, userScore );

        return userScore;

    },

    recordScore: function( score ) {

        $.post('score_ref/' + currentMvID + '/' + score + '.json', function(data) {
            // Todo: alert user if failure to save score
        });

    },

    giveFeedback: function ( answerRef, correctRef, userScore) {

        var msg;
        var $feedback;
        var answerBk, answerCh, answerVs;

        switch (userScore) {
            case 10:
                msg = "Perfect!";
                break;
            case 5:
                msg = "Correct book and chapter.";
                break;
            case 1:
                msg = "Correct book.";
                break;
            case 0:
                msg = "Incorrect.";
                break;
            default:
                msg = "Something weird happened!";
        }

        // answerRef will be false if user did not enter a parseable single verse
        // Override null values
        answerBk = (answerRef == false ) ? '- ' : answerRef.bk;
        answerCh = (answerRef == false ) ? '-'  : answerRef.ch;
        answerVs = (answerRef == false ) ? '-'  : answerRef.vs;

        $feedback = $('<div/>').addClass('prior-feedback')
            .append( $('<span class="prior-question"/>').text( correctRef.bk + ' ' + correctRef.ch + ":" + correctRef.vs ) )
            .append( $('<span class="divider"       />').text( ' - ' ) )
            .append( $('<span class="prior-answer"  />').text( '[' + answerBk + ' ' + answerCh + ":" + answerVs + '] ' ) )
            .append( $('<span class="prior-feedback"/>').text( msg   ) );

        $("#past-questions").prepend( $feedback );

    },

    updateRefGrade: function ( questionScore ) {
        var newRefGrade;

        newRefGrade = Math.ceil( this.refGrade * 0.90 + questionScore );
        this.refGrade = newRefGrade;
        this.saveRefGrade( newRefGrade );   // save to server
        return newRefGrade;
    },

    saveRefGrade: function ( refGrade ) {
        $.post('save_ref_grade/' + refGrade + '.json', function(data) {
            // Todo: alert user if failure to save score
        });
    }

}