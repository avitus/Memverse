/**
 * jQuery QuickFlip v2.0
 * http://jonraasch.com/blog/quickflip-2-jquery-plugin
 *
 * Copyright (c) 2009 Jon Raasch (http://jonraasch.com/)
 * Licensed under the FreeBSD License (See terms below)
 *
 * @author Jon Raasch
 *
 * @projectDescription    jQuery plugin to create a flipping effect
 * 
 * @version 2.0.0
 * 
 * @requires jquery.js (tested with v 1.3.2)
 *
 *
 * TERMS OF USE - jQuery Scrolling Parallax
 * Open source under the FreeBSD License.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 *    1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 *    2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY JON RAASCH 'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL JON RAASCH OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * The views and conclusions contained in the software and documentation are those of the authors and should not be interpreted as representing official policies, either expressed or implied, of Jon Raasch, who is the man.
 * 
 *
 * FOR USAGE INSTRUCTIONS SEE THE DOCUMENATION AT: http://dev.jonraasch.com/quickflip/docs
 * 
 *
 */

( function( $ ) {
    $.quickFlip = {
        wrappers : [],
        options  : [],
        objs     : [],
        
        init : function( options, box ) {
            var options = options || {};
            
            options.closeSpeed = options.closeSpeed || 180;
            options.openSpeed  = options.openSpeed  || 120;
            
            options.ctaSelector = options.ctaSelector || '.quickFlipCta';
            
            options.refresh = options.refresh || false;
            
            options.easing = options.easing || 'swing';
            
            var $box = typeof( box ) != 'undefined' ? $(box) : $('.quickFlip');
            var $kids = $box.children();
            
            // define $box css
            if ( $box.css('position') == 'static' ) $box.css('position', 'relative');
            
            // define this index
            var i = $.quickFlip.wrappers.length;
            
            // close all but first panel before calculating dimensions
            $kids.each(function(j) {
                var $this = $(this);
                
                // attach standard click handler
                if ( options.ctaSelector ) $.quickFlip.attachHandlers($(options.ctaSelector, $this), i, j);

                if ( j ) $this.hide();
            });
            
            $.quickFlip.options.push( options );
            
            $.quickFlip.objs.push({$box : $($box), $kids : $($kids)});
            
            $.quickFlip.buildQuickFlip(i);
            
            
            
            // quickFlip set up again on window resize
            
            $(window).resize( function() {
                for ( var i = 0; i < $.quickFlip.wrappers.length; i++ ) {
                    $.quickFlip.removeFlipDivs(i);
                    
                    $.quickFlip.buildQuickFlip(i);
                }
            });
        },
        
        buildQuickFlip : function(i, currPanel) {
            // get box width and height
            $.quickFlip.options[i].panelWidth = $.quickFlip.options[i].panelWidth || $.quickFlip.objs[i].$box.width();
            $.quickFlip.options[i].panelHeight = $.quickFlip.options[i].panelHeight || $.quickFlip.objs[i].$box.height();
            
             // init quickFlip, gathering info and building necessary objects
            var options = $.quickFlip.options[i];
            
            var thisFlip = {
                wrapper    : $.quickFlip.objs[i].$box,
                index      : i,
                halfwidth  : parseInt( options.panelWidth / 2),
                classNames : [],
                panels     : [],
                flipDivs   : [],
                flipDivCols : [],
                currPanel   : currPanel || 0,
                options     : options
            };
            
            // define each panel
            $.quickFlip.objs[i].$kids.each(function(j) {
                var $thisPanel = addPanelCss( $(this) );
                
                thisFlip.panels.push( $thisPanel );
                thisFlip.classNames.push( $thisPanel[0].className );
                
                // build flipDivs
                var $flipDivs = buildFlip( thisFlip, j ).hide().appendTo(thisFlip.wrapper);
                
                thisFlip.flipDivs.push( $flipDivs );
                thisFlip.flipDivCols.push( $flipDivs.children() );
            });
            
            $.quickFlip.wrappers[i] = thisFlip;
            
            function buildFlip( x, y ) {
                var $out = $('<div></div>');
                
                var inner = x.panels[y].html();
                
                var $leftCol = $(buildFlipCol(x, x.classNames[y], inner)).appendTo( $out );
                var $rightCol = $(buildFlipCol(x, x.classNames[y], inner)).appendTo( $out );
                    
                $leftCol.css('right', x.halfwidth);
                $rightCol.css('left', x.halfwidth);
    
                $rightCol.children().css({
                    right : 0,
                    left : 'auto'
                });
                
                return $out;
            }
            
            // builds one column of the flip divs (left or right side)
            function buildFlipCol(x, classNames, inner ) {
                var $col = $('<div></div>');
                
                $col.css({
                    width : x.halfwidth,
                    height : options.panelHeight,
                    position : 'absolute',
                    top : 0,
                    overflow : 'hidden',
                    margin : 0,
                    padding : 0
                });
                
                var $inner = addPanelCss('<div></div>');
                $inner.addClass(classNames);
                $inner.html(inner);
                
                $col.html($inner);
                
                return $col;
            }
            
            // add css for inner panel
            function addPanelCss( $panel ) {
                if ( typeof( $panel.css ) == 'undefined' ) $panel = $( $panel );
                
                $panel.css({
                    position : 'absolute',
                    top : 0,
                    left : 0,
                    margin : 0,
                    padding : 0,
                    width : options.panelWidth,
                    height : options.panelHeight
                });
                
                return $panel;
            }
        },
        
        // function flip ( i is quickflip index, j is index of currently open panel)
        
        flip : function( i, nextPanel, repeater, options) {
        
            if ( typeof(i) != 'number' || typeof($.quickFlip.wrappers[i]) == 'undefined' ) return false;
            
            var x = $.quickFlip.wrappers[i];
        
            var j = x.currPanel;
            var k = ( typeof(nextPanel) != 'undefined' && nextPanel != null ) ? nextPanel : ( x.panels.length > j + 1 ) ? j + 1 : 0;
            x.currPanel = k;
            
            var repeater = typeof(repeater) != 'undefined' ? repeater : 1;
            
            var options = $.quickFlip.combineOptions( options, $.quickFlip.options[i] );
    
            x.panels[j].hide()
            
            // if refresh set, remove flipDivs and rebuild
            if ( options.refresh ) {
                $.quickFlip.removeFlipDivs(i);
                $.quickFlip.buildQuickFlip(i, k);
                
                x = $.quickFlip.wrappers[i];
            }
            
            x.flipDivs[j].show();
            
            // these are due to multiple animations needing a callback
            var panelFlipCount1 = 0;
            var panelFlipCount2 = 0;
            
            x.flipDivCols[j].animate( { width : 0 }, options.closeSpeed, options.easing, function() {
                if ( !panelFlipCount1 ) {
                    panelFlipCount1++;
                }
                else {
                    x.flipDivs[k].show();
                    
                    x.flipDivCols[k].css( 'width', 0 );
                    
                    x.flipDivCols[k].animate( { width : x.halfwidth }, options.openSpeed, options.easing, function() {
                        if ( !panelFlipCount2 ) {
                            panelFlipCount2++;
                        }
                        else {
                            
                            x.flipDivs[k].hide();
                            
                            x.panels[k].show();
                            
                            // handle any looping of the animation
                            switch( repeater ) {
                                case 0:
                                case -1:
                                    $.quickFlip.flip( i, null, -1);
                                    break;
                                
                                //stop if is last flip, and attach events for msie
                                case 1: 
                                    break;
                                    
                                default:
                                    $.quickFlip.flip( i, null, repeater - 1);
                                    break;
                            }
                        }
                    });
                }
            });
            
        },
        
        // attach click handlers
        attachHandlers : function($the_cta, i, panel) {
            //attach flip
            $the_cta.click(function(ev) {
                ev.preventDefault();
                $.quickFlip.flip(i);
            });
        },
        
        removeFlipDivs : function(i) {
            for ( var j = 0; j < $.quickFlip.wrappers[i].flipDivs.length; j++ ) $.quickFlip.wrappers[i].flipDivs[j].remove();
        },
        
        compareObjs : function(obj1, obj2) {
            if (!obj1 || !obj2 || !obj1.length || !obj2.length || obj1.length != obj2.length) return false;
            
            for ( var i=0; i < obj1.length; i++ ) {
                if (obj1[i]!==obj2[i]) return false;
            }
            return true;
        },
        
        combineOptions : function( opts1, opts2 ) {
            opts1 = opts1 || {};
            opts2 = opts2 || {};
            
            for ( x in opts1 ) {
                opts2[x] = opts1[x];
            }
            
            return opts2;
        }
    };

    $.fn.quickFlip = function( options ) {
        this.each( function() {
            new $.quickFlip.init( options, this );
        });
        
        return this;
    };
    
    $.fn.whichQuickFlip = function() {
        var out = null;
        
        for ( var i=0; i < $.quickFlip.wrappers.length; i++ ) {
            if ( $.quickFlip.compareObjs(this, $( $.quickFlip.wrappers[i].wrapper)) ) out = i;
        }
        
        return out;
    };
    
    $.fn.quickFlipper = function( options, nextPanel, repeater ) {
        this.each( function() {
            var $this = $(this);
            var thisIndex = $this.whichQuickFlip();
            
            // if doesnt exist, set it up
            if ( thisIndex == null ) {
                $this.quickFlip( options );
                
                thisIndex = $this.whichQuickFlip();
            }
            
            $.quickFlip.flip( thisIndex, nextPanel, repeater, options );
        });
    };
    
})( jQuery );