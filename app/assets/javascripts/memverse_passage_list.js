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

    expandPassage: function ( $passageLocation, passageID ) {

        // collapse any other expanded passages
        $('.mv-list-details').fadeOut();

        // TODO: check whether we have already downloaded the memory verses for this passage

        // retrieve memory verses for passage
        $.getJSON('/passages/' + passageID + '/memverses.json', function (data) {
            passageListState.insertMemoryVerses( $passageLocation, data )
        });
    },

    insertMemoryVerses: function ( $passageLocation, memoryVerseArray ) {

        // build HTML for list of memory verses
        var $mvList = buildHTMLforMvList( memoryVerseArray );

        // insert entire list into page
        $passageLocation.append( $mvList );

    }

};


/******************************************************************************
 * Returns a div with a list of all memory verses and their details
 * Note: this is a core function for building lists of memory verses
 ******************************************************************************/
function buildHTMLforMvList ( mv_array ) {

    var $mvList         = $('<div/>').addClass("mv-list-details");

    // Build HTML for memory verse
    var $mvListHeadings = $('<div/>').addClass("mv-headings ")
        .append( $('<span class="mv-reference"  />').text( "Ref"        ))
        .append( $('<span class="mv-text"       />').text( "Text"       ))
        .append( $('<span class="mv-interval"   />').text( "Interval"   ))
        .append( $('<span class="mv-next_date"  />').text( "Next Test"  ))
        .append( $('<span class="mv-subsection" />').text( "Subsection" ));

    // Add headings
    $mvList.append( $mvListHeadings );

    // Add each verse in passage
    $.each( mv_array, function( index, mv ) {
        $mvDiv = buildHTMLforMvDetails( mv );
        $mvList.append( $mvDiv );
    })

    return $mvList;

}

/******************************************************************************
 * Returns a div containing all memverse details for display in a list of
 * memory verses
 * Note: this is a core function for displaying a memory verses in a list
 ******************************************************************************/
function buildHTMLforMvDetails ( mv ) {

    // Show start of verse
    var shortText = jQuery.trim(mv.text).substring(0, 35).split(" ").slice(0, -1).join(" ") + "...";

    // Build HTML for memory verse
    var $mvDiv = $('<div/>').addClass("mv-details ")
        .append( $('<span class="mv-reference"  />').text( mv.ref           ))
        .append( $('<span class="mv-text"       />').text( shortText        ))
        .append( $('<span class="mv-interval"   />').text( mv.test_interval ))
        .append( $('<span class="mv-next_date"  />').text( mv.next_test     ))
        .append( $('<span class="mv-subsection" />').text( mv.subsection    ));

    return $mvDiv;

}