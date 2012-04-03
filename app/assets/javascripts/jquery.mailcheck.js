(function($){
  $.fn.mailcheck = function(domains, opts) {
    var result = Kicksend.mailcheck.suggest(this.val(), domains);
    if (result) {
      if (opts.suggested) {
        opts.suggested(this, result);
      }
    } else {
      if (opts.empty) {
        opts.empty(this);
      }
    }
  };
})(jQuery);

var Kicksend = {
  mailcheck : {
    threshold: 2,

    suggest: function(email, domains) {
      var parts = email.split('@');
      if (parts < 2) {
        return false;
      }

      var closestDomain = this.findClosestDomain(parts[1], domains);

      if (closestDomain) {
        return { address: parts[0], domain: closestDomain, full: parts[0] + "@" + closestDomain }
      } else {
        return false;
      }
    },

    findClosestDomain: function(domain, domains) {
      var dist;
      var minDist = 99;
      var closestDomain = null;

      for (var i = 0; i < domains.length; i++) {
        dist = this.stringDistance(domain, domains[i]);
        if (dist < minDist) {
          minDist = dist;
          closestDomain = domains[i];
        }
      }

      if (minDist <= this.threshold && closestDomain !== null && closestDomain !== domain) {
        return closestDomain;
      } else {
        return false;
      }
    },

    stringDistance: function(s1, s2) {
      // sift3: http://siderite.blogspot.com/2007/04/super-fast-and-accurate-string-distance.html
      if (s1 == null || s1.length === 0) {
        if (s2 == null || s2.length === 0) {
          return 0;
        } else {
          return s2.length;
        }
      }

      if (s2 == null || s2.length === 0) {
        return s1.length;
      }

      var c = 0;
      var offset1 = 0;
      var offset2 = 0;
      var lcs = 0;
      var maxOffset = 5;

      while ((c + offset1 < s1.length) && (c + offset2 < s2.length)) {
        if (s1[c + offset1] == s2[c + offset2]) {
          lcs++;
        } else {
          offset1 = 0;
          offset2 = 0;
          for (var i = 0; i < maxOffset; i++) {
            if ((c + i < s1.length) && (s1[c + i] == s2[c])) {
              offset1 = i;
              break;
            }
            if ((c + i < s2.length) && (s1[c] == s2[c + i])) {
              offset2 = i;
              break;
            }
          }
        }
        c++;
      }
      return (s1.length + s2.length) /2 - lcs;
    }
  }
};