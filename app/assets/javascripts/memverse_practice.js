/******************************************************************************
 * Display compact list of verse references
 ******************************************************************************/
function displayMvSearchResultsFn( verses ) {
    resetScrollable();

    // if we have an array
    $(".mv-search-results-compact #actions a, .mv-search-results-compact div.scrollable, .mv-search-results-compact").show();
    
    /*-- $("#verse-search-single-result").hide(); --*/
    
    $.each (verses, function(i, pv) {
        
        // We need to group search results to enable scroll      
        if (i % 7 == 0) {
            // Start new group
            var $new_vs_group = $('<div/>').addClass('search-result-group');
            $('.items').append($new_vs_group);
        }

        // Show start of verse
        var shortText = jQuery.trim(pv.text).substring(0, 35).split(" ").slice(0, -1).join(" ") + "...";

        // Build HTML for each verse
        var $new_pv = $('<div/>').addClass('item')
            
            // verse reference
            .append( $('<div class="ref-and-first-words" />')
                .append($('<h4/>').text(pv.ref))
                .append($('<p/>').text( shortText )) 
            )
            
            // add button
            .append('<div class="select-verse-button"><a data-remote="true" href="/add/' + pv.id + '" class="compact-add-button" id="quick-start-add"></a></div>');

        $('.search-result-group').filter(':last').append($new_pv);                                                              
    }); 


    // if we have a single verse
    
}

