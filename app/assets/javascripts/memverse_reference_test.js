var refTestState = {

    // setup
    initialize: function () {

        refTestState.getRef();

    },

    getRef: function () {

        // Retrieve a reference for testing
        $.getJSON('test_next_ref.json', function (data) {

            var verseText = data.ref.text;

            // Add entire list
            $('#reftestVerse').html( verseText );

        });

    },

    scoreRef: function () {

        // Submit answer
        $.getJSON("/mark_reftest", { mv: id, q: q  }, function(data) {
            if (data.msg) {  setTimeout(function() {alert(data.msg);}, 1); }  // Give user a non-blocking response
        });

    }

}