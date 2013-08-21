var refTestState = {

    currentRef: null,
    refGrade: null,

    // setup
    initialize: function ( refGrade ) {

        refTestState.getRef();
        this.currentRef = "";
        this.refGrade = refGrade;

    },

    getRef: function () {

        // Retrieve a reference for testing
        $.getJSON('test_next_ref.json', function (data) {

            var mvText  = data.mv.text;
            currentRef  = data.mv.ref;

            $('#answer').val('').focus();       // Clear entry box
            $('#reftestVerse').html( mvText );  // Show verse text

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

        this.giveFeedback( answerRef, correctRef, userScore );

        return userScore;

    },

    giveFeedback: function ( answerRef, correctRef, userScore) {

        var msg;
        var $feedback

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

        $feedback = $('<div/>').addClass('prior-feedback')
            .append( $('<span class="prior-question"/>').text( correctRef.bk + ' ' + correctRef.ch + ":" + correctRef.vs ) )
            .append( $('<span class="divider"       />').text( ' - ' ) )
            .append( $('<span class="prior-answer"  />').text( '[' + answerRef.bk + ' ' + answerRef.ch + ":" + answerRef.vs + '] ' ) )
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