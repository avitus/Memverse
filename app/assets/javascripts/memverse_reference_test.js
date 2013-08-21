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

        return userScore;

    },

    updateRefGrade: function ( questionScore ) {
        var newRefGrade;

        newRefGrade = Math.ceil( this.refGrade * 0.95 + questionScore * 0.5 );
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