// kentbrew, gist 921146, https://gist.github.com/921146
// Updated to have function name and only run when called

function fauxPlaceholder () {
	(function (w, d, a) {
	  var $ = w[a.k] = {};
	  $.a = a;
	  $.w = w;
	  $.d = d;
	  $.f = (function () { 
	    return {
	      getEl: function (v) {
	        // helper: which is the target of this event?
	        var el;
	        if (v.target) {
	          el = (v.target.nodeType === 3) ? v.target.parentNode : v.target;
	        }
	        else {
	          el = v.srcElement;
	        }
	        return el;
	      },
	      getPrev : function (el) {
	        // helper: which is this element's previous sibling?
	        var prevSib = el.previousSibling;
	        if (prevSib && prevSib.nodeType !== 1) {
	          prevSib = prevSib.previousSibling;
	        }
	        return prevSib;
	      },
	      getNext : function (el) {
	        // helper: which is this element's next sibling?
	        var nextSib = el.nextSibling;
	        if (nextSib && nextSib.nodeType !== 1) {
	          nextSib = nextSib.nextSibling;
	        }
	        return nextSib;
	      },
	      focus: function (e) {
	        var v = e || $.w.event, el = $.f.getEl(v), span = $.f.getPrev(el);
	        if (span) {
	          // always hide the placeholder
	          span.style.display = 'none';
	        }
	      },
	      blur: function (e) { 
	        var v = e || $.w.event, el = $.f.getEl(v), span = $.f.getPrev(el);
	        if (span && span.tagName === 'SPAN') {
	          if (!el.value) {
	            // field has no value; show placeholder
	            span.style.display = 'block';
	          } else {
	            // field has value; hide placeholder
	            span.style.display = 'none';
	          }
	        }
	      },
	      down: function (e) {
	        var v = e || $.w.event, span = $.f.getEl(v);
	        // always hide the placeholder
	        span.style.display = 'none';
	        $.f.getNext(span).focus();
	      },
	      listen : function (el, ev, fn) {
	        // helper: gracefully attach an event
	        if(typeof $.w.addEventListener !== 'undefined') {
	          el.addEventListener(ev, fn, false);
	        } else if(typeof $.w.attachEvent !== 'undefined') {
	          el.attachEvent('on' + ev, fn);
	        }
	      },  
	      makePlaceholder : function (input, placeholder) {
	        var span, rule;
	        if (input.type === 'text' || input.type === 'password' ) {
	          span = $.d.createElement('SPAN');
	          span.innerHTML = placeholder;
	          span.style.position = 'absolute';
	          span.style.lineHeight = input.offsetHeight + 'px';
	          for (rule in $.a.style) {
	            if ($.a.style.hasOwnProperty(rule)) {
	              span.style[rule] = $.a.style[rule];
	            }
	          }
	          if (input.value) {
	            span.style.display = 'none';
	          }
	          input.parentNode.insertBefore(span, input);
	          $.f.listen(span, 'mousedown', $.f.down);
	          $.f.listen(input, 'focus', $.f.focus);
	          $.f.listen(input, 'blur', $.f.blur);
	        }
	      },
	      init : function () {
	        // no need to do any of this for browsers that understand placeholders
	        if ('placeholder' in $.d.createElement('INPUT')) {
	          return;
	        } 
	        var el, input, i, n, placeholder;
	        input = $.d.getElementsByTagName('INPUT');
	        for (i = 0, n = input.length; i < n; i = i + 1) {
	          el = input[i];
	          placeholder = el.getAttribute('placeholder');
	          if (placeholder) {
	            $.f.makePlaceholder(el, placeholder);
	          }
	        }
	      }      
	    };
	  }());
	  $.f.listen($.w, 'load', $.f.init);                                               
	}(window, document, {'k': 'IP', 'style': {'fontSize':'87%', 'marginLeft':'5px', 'color':'#aaa'}}));
}