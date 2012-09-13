/******************************************************************************
 * Display compact list of verse references
 ******************************************************************************/
function displayMvSearchResultsFn( verses ) {
    // if we have an array
    $(".mv-search-results-compact #actions a, .mv-search-results-compact div.scrollable, .mv-search-results-compact").show();
    
    /*-- $("#verse-search-single-result").hide(); --*/
    
    $.each (verses, function(i, pv) {
        // We need to group popular verses      
        if (i % 10 == 0) {
            // Start new group
            var $new_vs_group = $('<div/>').addClass('pop-verse-group');
            $('.items').append($new_vs_group);
        } 
        var $new_pv = $('<div/>').addClass('item quick-start-show-verse')
            .append($('<div class="verse-and-ref" />')
                .append($('<h4/>').text(pv.ref))
                .append($('<p/>').text(pv.text)) )
            .append('<div class="add-verse-button"><a data-remote="true" href="/add/' + pv.id + '" class="quick-start-add-button" id="quick-start-add"></a></div>');
        $('.pop-verse-group').filter(':last').append($new_pv);                                                              
    }); 
    // if we have a single verse
    
}

