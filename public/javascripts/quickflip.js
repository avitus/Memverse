/* QuickFlip jQuery Plugin
 * Author  :   Jon Raasch 
 * Website :   http://jonraasch.com/blog/quickflip-jquery-plugin
 * Contact :   jr@jonraasch.com
 * Version :   0.1
 *
 * Copyright (c)2008 Jon Raasch. All rights reserved.
 * Released under FreeBSD License, see readme.txt
 * Do not remove the above copyright notice or text
 *
 *
 *
 * Place any markup within one or more $('.quickFlipPanel') in $('quickFlip')
 * $('.quickFlipPanel .quickFlipCta') will automatically flip the panel when 
 * clicked.
 * 
 * Example:
 * 
 * <div class="quickFlip">
 *    <div class="quickFlipPanel">
 *    <p> Front content here </p>   
 *    <a href="#" class="quickFlipCta">Click to flip</a>
 *    </div>
 * 
 *    <div class="quickFlipPanel">
 *    <p> Back content here </p>
 *    <a href="#" class="quickFlipCta">Click to flip</a>
 *    </div>
 * </div>
 * 
 * You can also trigger the flip manually with quickFlip.flip( wrapper, panel, 
 * times to flip).  Times to flip is an integer for number of times, or use -1 
 * to flip continuously.
 * 
 * You must set a height and width for .quickFlip and .quickFlipPanel.  You can 
 * use additional class names on .quickFlipPanel, but don't attach an ID or  
 * inline style.  These can be attached to .quickFlip or anything within 
 * .quickFlipPanel
 *
 */

var quickFlip = {

    wrappers : [],
    newPanel : [],
    oldPanel : [],
    speed    : [ 180, 120 ], // close speed , open speed
    
    //function flip ( i is number of panel with quickflip class, i is number of currently open panel)
    
    createFlip : function( x, y, width ) {
        var out = '';
        
        for ( z = 0 ; z < 2 ; z++ ) {
            var theClass = (z == 0) ? 'flipColLeft' : 'flipColRight';
            var thePos = (z == 0) ? 'right' : 'left';
            
            out += '<div class="' + theClass + '" style="width: ' + width + 'px; height: ' + x.height + '; ' + thePos + ': ' + x.halfwidth + 'px;"><div class="' + x.classNames[y] + '">'  + x.panels[y].html() + '</div></div>'
        }
        return out;
    },
    
    flip : function( i, j, repeater) {
        var x = quickFlip.wrappers[i];
        
        var k = ( x.panels.length > j + 1 ) ? j + 1 : 0;
        
        quickFlip.newPanel = Array( i, k );
        quickFlip.oldPanel = Array( i, j );
        
        var flipDiv = quickFlip.createFlip( x, j, x.halfwidth);
        
        var flipDiv2 = quickFlip.createFlip( x, k, 0);

        x.panels[j].hide()
        x.wrapper.append(flipDiv);
                
        var $panel1 = $('.flipColLeft, .flipColRight', x.wrapper);
        
        var count1 = 0;
        var count2 = 0;
        
        var speed = (typeof(x.speed) == 'undefined') ? quickFlip.speed : x.speed
        
        $panel1.animate( { width : 0 }, speed[0], function() {
            if ( ! count1 ) count1++;
            else {
                $panel1.remove();
                x.wrapper.append(flipDiv2);
                var $panel2 = $('.flipColLeft, .flipColRight', x.wrapper);
                
                $panel2.animate( { width : x.halfwidth }, speed[1], function() {
                    if ( !count2 ) count2++;
                    else {
                        $panel2.remove();
                        x.panels[k].show();
                                                
                        switch( repeater ) {
                            case -1:
                                quickFlip.flip( i, k, -1);
                                break;
                            case 1: //stop if is last flip, and attach events for msie
                                if ($.browser.msie) {
                                    if ( typeof(quickFlip.reattachEvents) == 'function' ) quickFlip.reattachEvents();
                                    
                                    quickFlip.attachHandlers($('.quickFlipCta', x.panels[k]), i, k);
                                }
                                
                                break;
                            default:
                                quickFlip.flip( i, k, repeater-1);
                                break;
                        }
                    }
                });
            }
        });
        
    },
    
    attachHandlers : function($the_cta, i, panel) {
        //attach flip
        $the_cta.click(function(ev) {
            ev.preventDefault();
            quickFlip.flip(i, panel, 1);
        });
    },

    init : function() {
        quickFlip.wrappers = new Array();
        
        //gather info for each quickFlip panel
        $('.quickFlip').each(function(i) {
            var $this = $(this);            
            var thisFlip = {
                wrapper    : $this,
                halfwidth  : parseInt( parseInt( $this.css('width') )/2),
                height     : $this.css('height'),
                classNames : [],
                panels     : []
            };
            
            $this.children('.quickFlipPanel').each(function(j) {
                var $thisPanel = $(this);
                
                thisFlip.panels.push($thisPanel);
                thisFlip.classNames.push( $thisPanel[0].className );
                
                quickFlip.attachHandlers($('.quickFlipCta', $thisPanel), i, j);
                
                if ( j ) $thisPanel.hide();
            });
            
            quickFlip.wrappers.push(thisFlip);
        });
    }
}


$(function() {
    quickFlip.init();
});