var passageListState = {

    passageIDArray: [],    // Array holding ActiveRecord ID's of passages

    // setup
    initialize: function ( passageIDs ) {
        // Keep array of passage IDs
        passageIDArray = passageIDs;
    },

    showPassagesProgress: function () {

        $.each(passageIDArray, function( index, passageID ) {


            $.getJSON('/passages/' + passageID + '.json', function (data) {

                console.log(passageID + ': ' + data.ref + ' - ' + data.interval_array );

                var $passageProgress = $("#" + "id-" + passageID );

                // Insert <div> for each memory verse in passage
                $.each( data.interval_array, function( index, mvInterval ) {

                    var bgColorClass = passageListState.calcBackgroundColorCSSClass( mvInterval );

                    // Build HTML for each interval
                    var $vsIntervalDiv = $('<div/>').addClass("mv-interval " + "interval-" + mvInterval + " " + bgColorClass ).text( mvInterval );

                    // Add <div> to page
                    $passageProgress.append( $vsIntervalDiv );

                });

            });
        });
    },

    calcBackgroundColorCSSClass: function ( test_interval ) {
        if ( test_interval <= 1 ) {
            return "getting-started";
        }
        else if ( test_interval <= 15 ) {
            return "learning";
        }
        else if ( test_interval <= 29 ) {
            return "almost-memorized";
        }
        else if ( test_interval <= 90 ) {
            return "memorized";
        }
        else if ( test_interval <= 200 ) {
            return "well-known";
        }
        else {
            return "perfected";
        }
    },

    retrieveMemverses: function ( passageRef, passageID ) {
        // retrieve memory verses for passage
        $.getJSON('passages/' + passageID + '/memverses.json', function (data) {
            // display passage
            mvDisplayPassageForReview( passageRef, passageID, data )
        });
    }


}