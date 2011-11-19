


<!DOCTYPE html>
<html>
  <head>
    <meta charset='utf-8'>
    <meta http-equiv="X-UA-Compatible" content="chrome=1">
        <title>public/application.js at master from maccman/juggernaut - GitHub</title>
    <link rel="search" type="application/opensearchdescription+xml" href="/opensearch.xml" title="GitHub" />
    <link rel="fluid-icon" href="https://github.com/fluidicon.png" title="GitHub" />

    
    

    <meta content="authenticity_token" name="csrf-param" />
<meta content="bc0194f7586fd3dcbce3060033129391aece35d7" name="csrf-token" />

    <link href="https://a248.e.akamai.net/assets.github.com/stylesheets/bundles/github-ed04e8b8be3e88286d2fedb5ade5607df0599719.css" media="screen" rel="stylesheet" type="text/css" />
    

    <script src="https://a248.e.akamai.net/assets.github.com/javascripts/bundles/jquery-0afaa9d8025004af7fc6f2a561837057d3f21298.js" type="text/javascript"></script>
    <script src="https://a248.e.akamai.net/assets.github.com/javascripts/bundles/github-b1872f46a080aa92c45573ca095de24a21d5f9ff.js" type="text/javascript"></script>
    

      <link rel='permalink' href='/maccman/juggernaut/blob/fe672b36c14ac5ed53cfd4105cfc2577d4300d6b/public/application.js'>
    

    <meta name="description" content="juggernaut - Realtime server push with node.js, WebSockets and Comet" />
  <link href="https://github.com/maccman/juggernaut/commits/master.atom" rel="alternate" title="Recent Commits to juggernaut:master" type="application/atom+xml" />

  </head>


  <body class="logged_in page-blob linux env-production ">
    


    

    <div id="main">
      <div id="header" class="true">
          <a class="logo" href="https://github.com/">
            <img alt="github" class="default svg" height="45" src="https://a248.e.akamai.net/assets.github.com/images/modules/header/logov6.svg" />
            <img alt="github" class="default png" height="45" src="https://a248.e.akamai.net/assets.github.com/images/modules/header/logov6.png" />
            <!--[if (gt IE 8)|!(IE)]><!-->
            <img alt="github" class="hover svg" height="45" src="https://a248.e.akamai.net/assets.github.com/images/modules/header/logov6-hover.svg" />
            <img alt="github" class="hover png" height="45" src="https://a248.e.akamai.net/assets.github.com/images/modules/header/logov6-hover.png" />
            <!--<![endif]-->
          </a>

          


    <div class="userbox">
      <div class="avatarname">
        <a href="https://github.com/avitus"><img height="20" src="https://secure.gravatar.com/avatar/a9af65797401d61f7579e7c9d499ac30?s=140&amp;d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png" width="20" /></a>
        <a href="https://github.com/avitus" class="name">avitus</a>

      </div>
      <ul class="usernav">
        <li><a href="https://github.com/">Dashboard</a></li>
        <li>
          <a href="https://github.com/inbox">Inbox</a>
          <a href="https://github.com/inbox" class="unread_count ">0</a>
        </li>
        <li><a href="https://github.com/account">Account Settings</a></li>
        <li><a href="/logout">Log Out</a></li>
      </ul>
    </div><!-- /.userbox -->


        <div class="topsearch">
<form action="/search" id="top_search_form" method="get">      <a href="/search" class="advanced-search tooltipped downwards" title="Advanced Search">Advanced Search</a>
      <div class="search placeholder-field js-placeholder-field">
        <label class="placeholder" for="global-search-field">Search…</label>
        <input type="text" class="search my_repos_autocompleter" id="global-search-field" name="q" results="5" /> <input type="submit" value="Search" class="button" />
      </div>
      <input type="hidden" name="type" value="Everything" />
      <input type="hidden" name="repo" value="" />
      <input type="hidden" name="langOverride" value="" />
      <input type="hidden" name="start_value" value="1" />
</form>    <ul class="nav">
        <li class="explore"><a href="https://github.com/explore">Explore GitHub</a></li>
        <li><a href="https://gist.github.com">Gist</a></li>
        <li><a href="/blog">Blog</a></li>
      <li><a href="http://help.github.com">Help</a></li>
    </ul>
</div>

      </div>

      
            <div class="site">
      <div class="pagehead repohead vis-public   instapaper_ignore readability-menu">


      <div class="title-actions-bar">
        <h1>
          <a href="/maccman">maccman</a> /
          <strong><a href="/maccman/juggernaut" class="js-current-repository">juggernaut</a></strong>
        </h1>
        



            <ul class="pagehead-actions">

        <li class="js-toggler-container watch-button-container on">
          <a href="/maccman/juggernaut/toggle_watch" class="minibutton btn-watch watch-button js-toggler-target" data-method="post" data-remote="true"><span><span class="icon"></span>Watch</span></a>
          <a href="/maccman/juggernaut/toggle_watch" class="minibutton btn-watch unwatch-button js-toggler-target" data-method="post" data-remote="true"><span><span class="icon"></span>Unwatch</span></a>
        </li>
            <li><a href="/maccman/juggernaut/fork" class="minibutton btn-fork fork-button" data-method="post"><span><span class="icon"></span>Fork</span></a></li>

      <li class="repostats">
        <ul class="repo-stats">
          <li class="watchers watching">
            <a href="/maccman/juggernaut/watchers" title="Watchers — You&#39;re Watching" class="tooltipped downwards">
              957
            </a>
          </li>
          <li class="forks">
            <a href="/maccman/juggernaut/network" title="Forks" class="tooltipped downwards">
              74
            </a>
          </li>
        </ul>
      </li>
    </ul>

      </div>

        

  <ul class="tabs">
    <li><a href="/maccman/juggernaut" class="selected" highlight="repo_sourcerepo_downloadsrepo_commitsrepo_tagsrepo_branches">Code</a></li>
    <li><a href="/maccman/juggernaut/network" highlight="repo_networkrepo_fork_queue">Network</a>
    <li><a href="/maccman/juggernaut/pulls" highlight="repo_pulls">Pull Requests <span class='counter'>2</span></a></li>

      <li><a href="/maccman/juggernaut/issues" highlight="repo_issues">Issues <span class='counter'>21</span></a></li>

      <li><a href="/maccman/juggernaut/wiki" highlight="repo_wiki">Wiki <span class='counter'>2</span></a></li>

    <li><a href="/maccman/juggernaut/graphs" highlight="repo_graphsrepo_contributors">Stats &amp; Graphs</a></li>

  </ul>

  
<div class="frame frame-center tree-finder" style="display:none"
      data-tree-list-url="/maccman/juggernaut/tree-list/fe672b36c14ac5ed53cfd4105cfc2577d4300d6b"
      data-blob-url-prefix="/maccman/juggernaut/blob/fe672b36c14ac5ed53cfd4105cfc2577d4300d6b"
    >

  <div class="breadcrumb">
    <b><a href="/maccman/juggernaut">juggernaut</a></b> /
    <input class="tree-finder-input" type="text" name="query" autocomplete="off" spellcheck="false">
  </div>

    <div class="octotip">
      <p>
        <a href="/maccman/juggernaut/dismiss-tree-finder-help" class="dismiss js-dismiss-tree-list-help" title="Hide this notice forever">Dismiss</a>
        <strong>Octotip:</strong> You've activated the <em>file finder</em>
        by pressing <span class="kbd">t</span> Start typing to filter the
        file list. Use <span class="kbd badmono">↑</span> and
        <span class="kbd badmono">↓</span> to navigate,
        <span class="kbd">enter</span> to view files.
      </p>
    </div>

  <table class="tree-browser" cellpadding="0" cellspacing="0">
    <tr class="js-header"><th>&nbsp;</th><th>name</th></tr>
    <tr class="js-no-results no-results" style="display: none">
      <th colspan="2">No matching files</th>
    </tr>
    <tbody class="js-results-list">
    </tbody>
  </table>
</div>

<div id="jump-to-line" style="display:none">
  <h2>Jump to Line</h2>
  <form>
    <input class="textfield" type="text">
    <div class="full-button">
      <button type="submit" class="classy">
        <span>Go</span>
      </button>
    </div>
  </form>
</div>


<div class="subnav-bar">

  <ul class="actions">
    
      <li class="switcher">

        <div class="context-menu-container js-menu-container">
          <span class="text">Current branch:</span>
          <a href="#"
             class="minibutton bigger switcher context-menu-button js-menu-target js-commitish-button btn-branch repo-tree"
             data-master-branch="master"
             data-ref="master">
            <span><span class="icon"></span>master</span>
          </a>

          <div class="context-pane commitish-context js-menu-content">
            <a href="javascript:;" class="close js-menu-close"></a>
            <div class="title">Switch Branches/Tags</div>
            <div class="body pane-selector commitish-selector js-filterable-commitishes">
              <div class="filterbar">
                <div class="placeholder-field js-placeholder-field">
                  <label class="placeholder" for="context-commitish-filter-field" data-placeholder-mode="sticky">Filter branches/tags</label>
                  <input type="text" id="context-commitish-filter-field" class="commitish-filter" />
                </div>

                <ul class="tabs">
                  <li><a href="#" data-filter="branches" class="selected">Branches</a></li>
                  <li><a href="#" data-filter="tags">Tags</a></li>
                </ul>
              </div>

                <div class="commitish-item branch-commitish selector-item">
                  <h4>
                      <a href="/maccman/juggernaut/blob/master/public/application.js" data-name="master">master</a>
                  </h4>
                </div>

                <div class="commitish-item tag-commitish selector-item">
                  <h4>
                      <a href="/maccman/juggernaut/blob/v2.1.0/public/application.js" data-name="v2.1.0">v2.1.0</a>
                  </h4>
                </div>

              <div class="no-results" style="display:none">Nothing to show</div>
            </div>
          </div><!-- /.commitish-context-context -->
        </div>

      </li>
  </ul>

  <ul class="subnav">
    <li><a href="/maccman/juggernaut" class="selected" highlight="repo_source">Files</a></li>
    <li><a href="/maccman/juggernaut/commits/master" highlight="repo_commits">Commits</a></li>
    <li><a href="/maccman/juggernaut/branches" class="" highlight="repo_branches">Branches <span class="counter">1</span></a></li>
    <li><a href="/maccman/juggernaut/tags" class="" highlight="repo_tags">Tags <span class="counter">1</span></a></li>
    <li><a href="/maccman/juggernaut/downloads" class="blank" highlight="repo_downloads">Downloads <span class="counter">0</span></a></li>
  </ul>

</div>

  
  
  


        

      </div><!-- /.pagehead -->

      




  
  <p class="last-commit">Latest commit to the <strong>master</strong> branch</p>

<div class="commit commit-tease js-details-container">
  <p class="commit-title ">
      <a href="/maccman/juggernaut"><a href="/maccman/juggernaut/commit/fe672b36c14ac5ed53cfd4105cfc2577d4300d6b" class="message">bump version</a></a>
      
  </p>
  <div class="commit-meta">
    <a href="/maccman/juggernaut/commit/fe672b36c14ac5ed53cfd4105cfc2577d4300d6b" class="sha-block">commit <span class="sha">fe672b36c1</span></a>

    <div class="authorship">
      <img class="gravatar" height="20" src="https://secure.gravatar.com/avatar/baf018e2cc4616e4776d323215c7136c?s=140&amp;d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png" width="20" />
      <span class="author-name"><a href="/maccman">maccman</a></span>
      authored <time class="js-relative-date" datetime="2011-10-31T07:25:12-07:00" title="2011-10-31 07:25:12">October 31, 2011</time>

    </div>
  </div>
</div>


  <div id="slider">

    <div class="breadcrumb" data-path="public/application.js/">
      <b><a href="/maccman/juggernaut/tree/fe672b36c14ac5ed53cfd4105cfc2577d4300d6b" class="js-rewrite-sha">juggernaut</a></b> / <a href="/maccman/juggernaut/tree/fe672b36c14ac5ed53cfd4105cfc2577d4300d6b/public" class="js-rewrite-sha">public</a> / application.js       <span style="display:none" id="clippy_4124" class="clippy-text">public/application.js</span>
      
      <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000"
              width="110"
              height="14"
              class="clippy"
              id="clippy" >
      <param name="movie" value="https://a248.e.akamai.net/assets.github.com/flash/clippy.swf?v5"/>
      <param name="allowScriptAccess" value="always" />
      <param name="quality" value="high" />
      <param name="scale" value="noscale" />
      <param NAME="FlashVars" value="id=clippy_4124&amp;copied=copied!&amp;copyto=copy to clipboard">
      <param name="bgcolor" value="#FFFFFF">
      <param name="wmode" value="opaque">
      <embed src="https://a248.e.akamai.net/assets.github.com/flash/clippy.swf?v5"
             width="110"
             height="14"
             name="clippy"
             quality="high"
             allowScriptAccess="always"
             type="application/x-shockwave-flash"
             pluginspage="http://www.macromedia.com/go/getflashplayer"
             FlashVars="id=clippy_4124&amp;copied=copied!&amp;copyto=copy to clipboard"
             bgcolor="#FFFFFF"
             wmode="opaque"
      />
      </object>
      

    </div>

    <div class="frames">
      <div class="frame frame-center" data-path="public/application.js/" data-permalink-url="/maccman/juggernaut/blob/fe672b36c14ac5ed53cfd4105cfc2577d4300d6b/public/application.js" data-title="public/application.js at master from maccman/juggernaut - GitHub" data-type="blob">
          <ul class="big-actions">
            <li><a class="file-edit-link minibutton js-rewrite-sha" href="/maccman/juggernaut/edit/fe672b36c14ac5ed53cfd4105cfc2577d4300d6b/public/application.js" data-method="post"><span>Edit this file</span></a></li>
          </ul>

        <div id="files">
          <div class="file">
            <div class="meta">
              <div class="info">
                <span class="icon"><img alt="Txt" height="16" src="https://a248.e.akamai.net/assets.github.com/images/icons/txt.png" width="16" /></span>
                <span class="mode" title="File Mode">100644</span>
                  <span>2 lines (2 sloc)</span>
                <span>30.83 kb</span>
              </div>
              <ul class="actions">
                <li><a href="/maccman/juggernaut/raw/master/public/application.js" id="raw-url">raw</a></li>
                  <li><a href="/maccman/juggernaut/blame/master/public/application.js">blame</a></li>
                <li><a href="/maccman/juggernaut/commits/master/public/application.js">history</a></li>
              </ul>
            </div>
              <div class="data type-javascript">
      <table cellpadding="0" cellspacing="0" class="lines">
        <tr>
          <td>
            <pre class="line_numbers"><span id="L1" rel="#L1">1</span>
<span id="L2" rel="#L2">2</span>
</pre>
          </td>
          <td width="100%">
                <div class="highlight"><pre><div class='line' id='LC1'>/*! Socket.IO.js build:0.8.6, development. Copyright(c) 2011 LearnBoost &lt;dev@learnboost.com&gt; MIT Licensed */</div><div class='line' id='LC2'>(function(a,b){var c=a;c.version=&quot;0.8.6&quot;;c.protocol=1;c.transports=[];c.j=[];c.sockets={};c.connect=function(h,f){var g=c.util.parseUri(h),i,d;if(b&amp;&amp;b.location){g.protocol=g.protocol||b.location.protocol.slice(0,-1);g.host=g.host||(b.document?b.document.domain:b.location.hostname);g.port=g.port||b.location.port}i=c.util.uniqueUri(g);var e={host:g.host,secure:&quot;https&quot;==g.protocol,port:g.port||(&quot;https&quot;==g.protocol?443:80),query:g.query||&quot;&quot;};c.util.merge(e,f);if(e[&quot;force new connection&quot;]||!c.sockets[i]){d=new c.Socket(e)}if(!e[&quot;force new connection&quot;]&amp;&amp;d){c.sockets[i]=d}d=d||c.sockets[i];return d.of(g.path.length&gt;1?g.path:&quot;&quot;)}})(&quot;object&quot;===typeof module?module.exports:(this.io={}),this);(function(b,d){var a=b.util={};var c=/^(?:(?![^:@]+:[^:@\/]*@)([^:\/?#.]+):)?(?:\/\/)?((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?)(((\/(?:[^?#](?![^?#\/]*\.[^?#\/.]+(?:[?#]|$)))*\/?)?([^?#\/]*))(?:\?([^#]*))?(?:#(.*))?)/;var e=[&quot;source&quot;,&quot;protocol&quot;,&quot;authority&quot;,&quot;userInfo&quot;,&quot;user&quot;,&quot;password&quot;,&quot;host&quot;,&quot;port&quot;,&quot;relative&quot;,&quot;path&quot;,&quot;directory&quot;,&quot;file&quot;,&quot;query&quot;,&quot;anchor&quot;];a.parseUri=function(l){var h=c.exec(l||&quot;&quot;),k={},j=14;while(j--){k[e[j]]=h[j]||&quot;&quot;}return k};a.uniqueUri=function(j){var k=j.protocol,i=j.host,h=j.port;if(&quot;document&quot; in d){i=i||document.domain;h=h||(k==&quot;https&quot;&amp;&amp;document.location.protocol!==&quot;https:&quot;?443:document.location.port)}else{i=i||&quot;localhost&quot;;if(!h&amp;&amp;k==&quot;https&quot;){h=443}}return(k||&quot;http&quot;)+&quot;://&quot;+i+&quot;:&quot;+(h||80)};a.query=function(l,h){var k=a.chunkQuery(l||&quot;&quot;),j=[];a.merge(k,a.chunkQuery(h||&quot;&quot;));for(var i in k){if(k.hasOwnProperty(i)){j.push(i+&quot;=&quot;+k[i])}}return j.length?&quot;?&quot;+j.join(&quot;&amp;&quot;):&quot;&quot;};a.chunkQuery=function(h){var n={},o=h.split(&quot;&amp;&quot;),k=0,j=o.length,m;for(;k&lt;j;++k){m=o[k].split(&quot;=&quot;);if(m[0]){n[m[0]]=decodeURIComponent(m[1])}}return n};var f=false;a.load=function(h){if(&quot;document&quot; in d&amp;&amp;document.readyState===&quot;complete&quot;||f){return h()}a.on(d,&quot;load&quot;,h,false)};a.on=function(i,k,j,h){if(i.attachEvent){i.attachEvent(&quot;on&quot;+k,j)}else{if(i.addEventListener){i.addEventListener(k,j,h)}}};a.request=function(h){if(h&amp;&amp;&quot;undefined&quot;!=typeof XDomainRequest){return new XDomainRequest()}if(&quot;undefined&quot;!=typeof XMLHttpRequest&amp;&amp;(!h||a.ua.hasCORS)){return new XMLHttpRequest()}if(!h){try{return new ActiveXObject(&quot;Microsoft.XMLHTTP&quot;)}catch(i){}}return null};if(&quot;undefined&quot;!=typeof window){a.load(function(){f=true})}a.defer=function(h){if(!a.ua.webkit||&quot;undefined&quot;!=typeof importScripts){return h()}a.load(function(){setTimeout(h,100)})};a.merge=function g(l,h,i,k){var j=k||[],m=typeof i==&quot;undefined&quot;?2:i,n;for(n in h){if(h.hasOwnProperty(n)&amp;&amp;a.indexOf(j,n)&lt;0){if(typeof l[n]!==&quot;object&quot;||!m){l[n]=h[n];j.push(h[n])}else{a.merge(l[n],h[n],m-1,j)}}}return l};a.mixin=function(i,h){a.merge(i.prototype,h.prototype)};a.inherit=function(i,h){function j(){}j.prototype=h.prototype;i.prototype=new j};a.isArray=Array.isArray||function(h){return Object.prototype.toString.call(h)===&quot;[object Array]&quot;};a.intersect=function(h,k){var m=[],o=h.length&gt;k.length?h:k,p=h.length&gt;k.length?k:h;for(var n=0,j=p.length;n&lt;j;n++){if(~a.indexOf(o,p[n])){m.push(p[n])}}return m};a.indexOf=function(h,m,l){if(Array.prototype.indexOf){return Array.prototype.indexOf.call(h,m,l)}for(var k=h.length,l=l&lt;0?l+k&lt;0?0:l+k:l||0;l&lt;k&amp;&amp;h[l]!==m;l++){}return k&lt;=l?-1:l};a.toArray=function(m){var h=[];for(var k=0,j=m.length;k&lt;j;k++){h.push(m[k])}return h};a.ua={};a.ua.hasCORS=&quot;undefined&quot;!=typeof XMLHttpRequest&amp;&amp;(function(){try{var h=new XMLHttpRequest()}catch(i){return false}return h.withCredentials!=undefined})();a.ua.webkit=&quot;undefined&quot;!=typeof navigator&amp;&amp;/webkit/i.test(navigator.userAgent)})(&quot;undefined&quot;!=typeof io?io:module.exports,this);(function(a,c){a.EventEmitter=b;function b(){}b.prototype.on=function(d,e){if(!this.$events){this.$events={}}if(!this.$events[d]){this.$events[d]=e}else{if(c.util.isArray(this.$events[d])){this.$events[d].push(e)}else{this.$events[d]=[this.$events[d],e]}}return this};b.prototype.addListener=b.prototype.on;b.prototype.once=function(f,g){var e=this;function d(){e.removeListener(f,d);g.apply(this,arguments)}d.listener=g;this.on(f,d);return this};b.prototype.removeListener=function(e,g){if(this.$events&amp;&amp;this.$events[e]){var h=this.$events[e];if(c.util.isArray(h)){var j=-1;for(var f=0,d=h.length;f&lt;d;f++){if(h[f]===g||(h[f].listener&amp;&amp;h[f].listener===g)){j=f;break}}if(j&lt;0){return this}h.splice(j,1);if(!h.length){delete this.$events[e]}}else{if(h===g||(h.listener&amp;&amp;h.listener===g)){delete this.$events[e]}}}return this};b.prototype.removeAllListeners=function(d){if(this.$events&amp;&amp;this.$events[d]){this.$events[d]=null}return this};b.prototype.listeners=function(d){if(!this.$events){this.$events={}}if(!this.$events[d]){this.$events[d]=[]}if(!c.util.isArray(this.$events[d])){this.$events[d]=[this.$events[d]]}return this.$events[d]};b.prototype.emit=function(f){if(!this.$events){return false}var j=this.$events[f];if(!j){return false}var e=Array.prototype.slice.call(arguments,1);if(&quot;function&quot;==typeof j){j.apply(this,e)}else{if(c.util.isArray(j)){var h=j.slice();for(var g=0,d=h.length;g&lt;d;g++){h[g].apply(this,e)}}else{return false}}return true}})(&quot;undefined&quot;!=typeof io?io:module.exports,&quot;undefined&quot;!=typeof io?io:module.parent.exports);(function(exports,nativeJSON){if(nativeJSON&amp;&amp;nativeJSON.parse){return exports.JSON={parse:nativeJSON.parse,stringify:nativeJSON.stringify}}var JSON=exports.JSON={};function f(n){return n&lt;10?&quot;0&quot;+n:n}function date(d,key){return isFinite(d.valueOf())?d.getUTCFullYear()+&quot;-&quot;+f(d.getUTCMonth()+1)+&quot;-&quot;+f(d.getUTCDate())+&quot;T&quot;+f(d.getUTCHours())+&quot;:&quot;+f(d.getUTCMinutes())+&quot;:&quot;+f(d.getUTCSeconds())+&quot;Z&quot;:null}var cx=/[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,escapable=/[\\\&quot;\x00-\x1f\x7f-\x9f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,gap,indent,meta={&quot;\b&quot;:&quot;\\b&quot;,&quot;\t&quot;:&quot;\\t&quot;,&quot;\n&quot;:&quot;\\n&quot;,&quot;\f&quot;:&quot;\\f&quot;,&quot;\r&quot;:&quot;\\r&quot;,'&quot;':'\\&quot;',&quot;\\&quot;:&quot;\\\\&quot;},rep;function quote(string){escapable.lastIndex=0;return escapable.test(string)?'&quot;'+string.replace(escapable,function(a){var c=meta[a];return typeof c===&quot;string&quot;?c:&quot;\\u&quot;+(&quot;0000&quot;+a.charCodeAt(0).toString(16)).slice(-4)})+'&quot;':'&quot;'+string+'&quot;'}function str(key,holder){var i,k,v,length,mind=gap,partial,value=holder[key];if(value instanceof Date){value=date(key)}if(typeof rep===&quot;function&quot;){value=rep.call(holder,key,value)}switch(typeof value){case&quot;string&quot;:return quote(value);case&quot;number&quot;:return isFinite(value)?String(value):&quot;null&quot;;case&quot;boolean&quot;:case&quot;null&quot;:return String(value);case&quot;object&quot;:if(!value){return&quot;null&quot;}gap+=indent;partial=[];if(Object.prototype.toString.apply(value)===&quot;[object Array]&quot;){length=value.length;for(i=0;i&lt;length;i+=1){partial[i]=str(i,value)||&quot;null&quot;}v=partial.length===0?&quot;[]&quot;:gap?&quot;[\n&quot;+gap+partial.join(&quot;,\n&quot;+gap)+&quot;\n&quot;+mind+&quot;]&quot;:&quot;[&quot;+partial.join(&quot;,&quot;)+&quot;]&quot;;gap=mind;return v}if(rep&amp;&amp;typeof rep===&quot;object&quot;){length=rep.length;for(i=0;i&lt;length;i+=1){if(typeof rep[i]===&quot;string&quot;){k=rep[i];v=str(k,value);if(v){partial.push(quote(k)+(gap?&quot;: &quot;:&quot;:&quot;)+v)}}}}else{for(k in value){if(Object.prototype.hasOwnProperty.call(value,k)){v=str(k,value);if(v){partial.push(quote(k)+(gap?&quot;: &quot;:&quot;:&quot;)+v)}}}}v=partial.length===0?&quot;{}&quot;:gap?&quot;{\n&quot;+gap+partial.join(&quot;,\n&quot;+gap)+&quot;\n&quot;+mind+&quot;}&quot;:&quot;{&quot;+partial.join(&quot;,&quot;)+&quot;}&quot;;gap=mind;return v}}JSON.stringify=function(value,replacer,space){var i;gap=&quot;&quot;;indent=&quot;&quot;;if(typeof space===&quot;number&quot;){for(i=0;i&lt;space;i+=1){indent+=&quot; &quot;}}else{if(typeof space===&quot;string&quot;){indent=space}}rep=replacer;if(replacer&amp;&amp;typeof replacer!==&quot;function&quot;&amp;&amp;(typeof replacer!==&quot;object&quot;||typeof replacer.length!==&quot;number&quot;)){throw new Error(&quot;JSON.stringify&quot;)}return str(&quot;&quot;,{&quot;&quot;:value})};JSON.parse=function(text,reviver){var j;function walk(holder,key){var k,v,value=holder[key];if(value&amp;&amp;typeof value===&quot;object&quot;){for(k in value){if(Object.prototype.hasOwnProperty.call(value,k)){v=walk(value,k);if(v!==undefined){value[k]=v}else{delete value[k]}}}}return reviver.call(holder,key,value)}text=String(text);cx.lastIndex=0;if(cx.test(text)){text=text.replace(cx,function(a){return&quot;\\u&quot;+(&quot;0000&quot;+a.charCodeAt(0).toString(16)).slice(-4)})}if(/^[\],:{}\s]*$/.test(text.replace(/\\(?:[&quot;\\\/bfnrt]|u[0-9a-fA-F]{4})/g,&quot;@&quot;).replace(/&quot;[^&quot;\\\n\r]*&quot;|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g,&quot;]&quot;).replace(/(?:^|:|,)(?:\s*\[)+/g,&quot;&quot;))){j=eval(&quot;(&quot;+text+&quot;)&quot;);return typeof reviver===&quot;function&quot;?walk({&quot;&quot;:j},&quot;&quot;):j}throw new SyntaxError(&quot;JSON.parse&quot;)}})(&quot;undefined&quot;!=typeof io?io:module.exports,typeof JSON!==&quot;undefined&quot;?JSON:undefined);(function(d,g){var a=d.parser={};var e=a.packets=[&quot;disconnect&quot;,&quot;connect&quot;,&quot;heartbeat&quot;,&quot;message&quot;,&quot;json&quot;,&quot;event&quot;,&quot;ack&quot;,&quot;error&quot;,&quot;noop&quot;];var b=a.reasons=[&quot;transport not supported&quot;,&quot;client not handshaken&quot;,&quot;unauthorized&quot;];var c=a.advice=[&quot;reconnect&quot;];var i=g.JSON,h=g.util.indexOf;a.encodePacket=function(k){var p=h(e,k.type),j=k.id||&quot;&quot;,r=k.endpoint||&quot;&quot;,s=k.ack,n=null;switch(k.type){case&quot;error&quot;:var o=k.reason?h(b,k.reason):&quot;&quot;,l=k.advice?h(c,k.advice):&quot;&quot;;if(o!==&quot;&quot;||l!==&quot;&quot;){n=o+(l!==&quot;&quot;?(&quot;+&quot;+l):&quot;&quot;)}break;case&quot;message&quot;:if(k.data!==&quot;&quot;){n=k.data}break;case&quot;event&quot;:var q={name:k.name};if(k.args&amp;&amp;k.args.length){q.args=k.args}n=i.stringify(q);break;case&quot;json&quot;:n=i.stringify(k.data);break;case&quot;connect&quot;:if(k.qs){n=k.qs}break;case&quot;ack&quot;:n=k.ackId+(k.args&amp;&amp;k.args.length?&quot;+&quot;+i.stringify(k.args):&quot;&quot;);break}var m=[p,j+(s==&quot;data&quot;?&quot;+&quot;:&quot;&quot;),r];if(n!==null&amp;&amp;n!==undefined){m.push(n)}return m.join(&quot;:&quot;)};a.encodePayload=function(o){var k=&quot;&quot;;if(o.length==1){return o[0]}for(var m=0,j=o.length;m&lt;j;m++){var n=o[m];k+=&quot;\ufffd&quot;+n.length+&quot;\ufffd&quot;+o[m]}return k};var f=/([^:]+):([0-9]+)?(\+)?:([^:]+)?:?([\s\S]*)?/;a.decodePacket=function(l){var k=l.match(f);if(!k){return{}}var o=k[2]||&quot;&quot;,l=k[5]||&quot;&quot;,n={type:e[k[1]],endpoint:k[4]||&quot;&quot;};if(o){n.id=o;if(k[3]){n.ack=&quot;data&quot;}else{n.ack=true}}switch(n.type){case&quot;error&quot;:var k=l.split(&quot;+&quot;);n.reason=b[k[0]]||&quot;&quot;;n.advice=c[k[1]]||&quot;&quot;;break;case&quot;message&quot;:n.data=l||&quot;&quot;;break;case&quot;event&quot;:try{var j=i.parse(l);n.name=j.name;n.args=j.args}catch(m){}n.args=n.args||[];break;case&quot;json&quot;:try{n.data=i.parse(l)}catch(m){}break;case&quot;connect&quot;:n.qs=l||&quot;&quot;;break;case&quot;ack&quot;:var k=l.match(/^([0-9]+)(\+)?(.*)/);if(k){n.ackId=k[1];n.args=[];if(k[3]){try{n.args=k[3]?i.parse(k[3]):[]}catch(m){}}}break;case&quot;disconnect&quot;:case&quot;heartbeat&quot;:break}return n};a.decodePayload=function(m){if(m.charAt(0)==&quot;\ufffd&quot;){var j=[];for(var k=1,l=&quot;&quot;;k&lt;m.length;k++){if(m.charAt(k)==&quot;\ufffd&quot;){j.push(a.decodePacket(m.substr(k+1).substr(0,l)));k+=Number(l)+1;l=&quot;&quot;}else{l+=m.charAt(k)}}return j}else{return[a.decodePacket(m)]}}})(&quot;undefined&quot;!=typeof io?io:module.exports,&quot;undefined&quot;!=typeof io?io:module.parent.exports);(function(a,c){a.Transport=b;function b(d,e){this.socket=d;this.sessid=e}c.util.mixin(b,c.EventEmitter);b.prototype.onData=function(g){this.clearCloseTimeout();if(this.connected||this.connecting||this.reconnecting){this.setCloseTimeout()}if(g!==&quot;&quot;){var f=c.parser.decodePayload(g);if(f&amp;&amp;f.length){for(var e=0,d=f.length;e&lt;d;e++){this.onPacket(f[e])}}}return this};b.prototype.onPacket=function(d){if(d.type==&quot;heartbeat&quot;){return this.onHeartbeat()}if(d.type==&quot;connect&quot;&amp;&amp;d.endpoint==&quot;&quot;){this.onConnect()}this.socket.onPacket(d);return this};b.prototype.setCloseTimeout=function(){if(!this.closeTimeout){var d=this;this.closeTimeout=setTimeout(function(){d.onDisconnect()},this.socket.closeTimeout)}};b.prototype.onDisconnect=function(){if(this.close&amp;&amp;this.open){this.close()}this.clearTimeouts();this.socket.onDisconnect();return this};b.prototype.onConnect=function(){this.socket.onConnect();return this};b.prototype.clearCloseTimeout=function(){if(this.closeTimeout){clearTimeout(this.closeTimeout);this.closeTimeout=null}};b.prototype.clearTimeouts=function(){this.clearCloseTimeout();if(this.reopenTimeout){clearTimeout(this.reopenTimeout)}};b.prototype.packet=function(d){this.send(c.parser.encodePacket(d))};b.prototype.onHeartbeat=function(d){this.packet({type:&quot;heartbeat&quot;})};b.prototype.onOpen=function(){this.open=true;this.clearCloseTimeout();this.socket.onOpen()};b.prototype.onClose=function(){var d=this;this.open=false;this.socket.onClose();this.onDisconnect()};b.prototype.prepareUrl=function(){var d=this.socket.options;return this.scheme()+&quot;://&quot;+d.host+&quot;:&quot;+d.port+&quot;/&quot;+d.resource+&quot;/&quot;+c.protocol+&quot;/&quot;+this.name+&quot;/&quot;+this.sessid};b.prototype.ready=function(d,e){e.call(this)}})(&quot;undefined&quot;!=typeof io?io:module.exports,&quot;undefined&quot;!=typeof io?io:module.parent.exports);(function(b,e,c){b.Socket=a;function a(g){this.options={port:80,secure:false,document:&quot;document&quot; in c?document:false,resource:&quot;socket.io&quot;,transports:e.transports,&quot;connect timeout&quot;:10000,&quot;try multiple transports&quot;:true,reconnect:true,&quot;reconnection delay&quot;:500,&quot;reconnection limit&quot;:Infinity,&quot;reopen delay&quot;:3000,&quot;max reconnection attempts&quot;:10,&quot;sync disconnect on unload&quot;:true,&quot;auto connect&quot;:true,&quot;flash policy port&quot;:10843};e.util.merge(this.options,g);this.connected=false;this.open=false;this.connecting=false;this.reconnecting=false;this.namespaces={};this.buffer=[];this.doBuffer=false;if(this.options[&quot;sync disconnect on unload&quot;]&amp;&amp;(!this.isXDomain()||e.util.ua.hasCORS)){var f=this;e.util.on(c,&quot;beforeunload&quot;,function(){f.disconnectSync()},false)}if(this.options[&quot;auto connect&quot;]){this.connect()}}e.util.mixin(a,e.EventEmitter);a.prototype.of=function(f){if(!this.namespaces[f]){this.namespaces[f]=new e.SocketNamespace(this,f);if(f!==&quot;&quot;){this.namespaces[f].packet({type:&quot;connect&quot;})}}return this.namespaces[f]};a.prototype.publish=function(){this.emit.apply(this,arguments);var g;for(var f in this.namespaces){if(this.namespaces.hasOwnProperty(f)){g=this.of(f);g.$emit.apply(g,arguments)}}};function d(){}a.prototype.handshake=function(l){var h=this,j=this.options;function f(n){if(n instanceof Error){h.onError(n.message)}else{l.apply(null,n.split(&quot;:&quot;))}}var i=[&quot;http&quot;+(j.secure?&quot;s&quot;:&quot;&quot;)+&quot;:/&quot;,j.host+&quot;:&quot;+j.port,j.resource,e.protocol,e.util.query(this.options.query,&quot;t=&quot;+ +new Date)].join(&quot;/&quot;);if(this.isXDomain()&amp;&amp;!e.util.ua.hasCORS){var k=document.getElementsByTagName(&quot;script&quot;)[0],g=document.createElement(&quot;script&quot;);g.src=i+&quot;&amp;jsonp=&quot;+e.j.length;k.parentNode.insertBefore(g,k);e.j.push(function(n){f(n);g.parentNode.removeChild(g)})}else{var m=e.util.request();m.open(&quot;GET&quot;,i,true);m.onreadystatechange=function(){if(m.readyState==4){m.onreadystatechange=d;if(m.status==200){f(m.responseText)}else{!h.reconnecting&amp;&amp;h.onError(m.responseText)}}};m.send(null)}};a.prototype.getTransport=function(j){var f=j||this.transports,g;for(var h=0,k;k=f[h];h++){if(e.Transport[k]&amp;&amp;e.Transport[k].check(this)&amp;&amp;(!this.isXDomain()||e.Transport[k].xdomainCheck())){return new e.Transport[k](this,this.sessionid)}}return null};a.prototype.connect=function(g){if(this.connecting){return this}var f=this;this.handshake(function(h,k,l,j){f.sessionid=h;f.closeTimeout=l*1000;f.heartbeatTimeout=k*1000;f.transports=e.util.intersect(j.split(&quot;,&quot;),f.options.transports);function i(m){if(f.transport){f.transport.clearTimeouts()}f.transport=f.getTransport(m);if(!f.transport){return f.publish(&quot;connect_failed&quot;)}f.transport.ready(f,function(){f.connecting=true;f.publish(&quot;connecting&quot;,f.transport.name);f.transport.open();if(f.options[&quot;connect timeout&quot;]){f.connectTimeoutTimer=setTimeout(function(){if(!f.connected){f.connecting=false;if(f.options[&quot;try multiple transports&quot;]){if(!f.remainingTransports){f.remainingTransports=f.transports.slice(0)}var n=f.remainingTransports;while(n.length&gt;0&amp;&amp;n.splice(0,1)[0]!=f.transport.name){}if(n.length){i(n)}else{f.publish(&quot;connect_failed&quot;)}}}},f.options[&quot;connect timeout&quot;])}})}i();f.once(&quot;connect&quot;,function(){clearTimeout(f.connectTimeoutTimer);g&amp;&amp;typeof g==&quot;function&quot;&amp;&amp;g()})});return this};a.prototype.packet=function(f){if(this.connected&amp;&amp;!this.doBuffer){this.transport.packet(f)}else{this.buffer.push(f)}return this};a.prototype.setBuffer=function(f){this.doBuffer=f;if(!f&amp;&amp;this.connected&amp;&amp;this.buffer.length){this.transport.payload(this.buffer);this.buffer=[]}};a.prototype.disconnect=function(){if(this.connected){if(this.open){this.of(&quot;&quot;).packet({type:&quot;disconnect&quot;})}this.onDisconnect(&quot;booted&quot;)}return this};a.prototype.disconnectSync=function(){var g=e.util.request(),f=this.resource+&quot;/&quot;+e.protocol+&quot;/&quot;+this.sessionid;g.open(&quot;GET&quot;,f,true);this.onDisconnect(&quot;booted&quot;)};a.prototype.isXDomain=function(){var f=c.location.port||(&quot;https:&quot;==c.location.protocol?443:80);return this.options.host!==c.location.hostname||this.options.port!=f};a.prototype.onConnect=function(){if(!this.connected){this.connected=true;this.connecting=false;if(!this.doBuffer){this.setBuffer(false)}this.emit(&quot;connect&quot;)}};a.prototype.onOpen=function(){this.open=true};a.prototype.onClose=function(){this.open=false};a.prototype.onPacket=function(f){this.of(f.endpoint).onPacket(f)};a.prototype.onError=function(f){if(f&amp;&amp;f.advice){if(f.advice===&quot;reconnect&quot;&amp;&amp;this.connected){this.disconnect();this.reconnect()}}this.publish(&quot;error&quot;,f&amp;&amp;f.reason?f.reason:f)};a.prototype.onDisconnect=function(g){var f=this.connected;this.connected=false;this.connecting=false;this.open=false;if(f){this.transport.close();this.transport.clearTimeouts();this.publish(&quot;disconnect&quot;,g);if(&quot;booted&quot;!=g&amp;&amp;this.options.reconnect&amp;&amp;!this.reconnecting){this.reconnect()}}};a.prototype.reconnect=function(){this.reconnecting=true;this.reconnectionAttempts=0;this.reconnectionDelay=this.options[&quot;reconnection delay&quot;];var i=this,h=this.options[&quot;max reconnection attempts&quot;],f=this.options[&quot;try multiple transports&quot;],g=this.options[&quot;reconnection limit&quot;];function j(){if(i.connected){for(var l in i.namespaces){if(i.namespaces.hasOwnProperty(l)&amp;&amp;&quot;&quot;!==l){i.namespaces[l].packet({type:&quot;connect&quot;})}}i.publish(&quot;reconnect&quot;,i.transport.name,i.reconnectionAttempts)}i.removeListener(&quot;connect_failed&quot;,k);i.removeListener(&quot;connect&quot;,k);i.reconnecting=false;delete i.reconnectionAttempts;delete i.reconnectionDelay;delete i.reconnectionTimer;delete i.redoTransports;i.options[&quot;try multiple transports&quot;]=f}function k(){if(!i.reconnecting){return}if(i.connected){return j()}if(i.connecting&amp;&amp;i.reconnecting){return i.reconnectionTimer=setTimeout(k,1000)}if(i.reconnectionAttempts++&gt;=h){if(!i.redoTransports){i.on(&quot;connect_failed&quot;,k);i.options[&quot;try multiple transports&quot;]=true;i.transport=i.getTransport();i.redoTransports=true;i.connect()}else{i.publish(&quot;reconnect_failed&quot;);j()}}else{if(i.reconnectionDelay&lt;g){i.reconnectionDelay*=2}i.connect();i.publish(&quot;reconnecting&quot;,i.reconnectionDelay,i.reconnectionAttempts);i.reconnectionTimer=setTimeout(k,i.reconnectionDelay)}}this.options[&quot;try multiple transports&quot;]=false;this.reconnectionTimer=setTimeout(k,this.reconnectionDelay);this.on(&quot;connect&quot;,k)}})(&quot;undefined&quot;!=typeof io?io:module.exports,&quot;undefined&quot;!=typeof io?io:module.parent.exports,this);(function(a,d){a.SocketNamespace=b;function b(e,f){this.socket=e;this.name=f||&quot;&quot;;this.flags={};this.json=new c(this,&quot;json&quot;);this.ackPackets=0;this.acks={}}d.util.mixin(b,d.EventEmitter);b.prototype.$emit=d.EventEmitter.prototype.emit;b.prototype.of=function(){return this.socket.of.apply(this.socket,arguments)};b.prototype.packet=function(e){e.endpoint=this.name;this.socket.packet(e);this.flags={};return this};b.prototype.send=function(f,e){var g={type:this.flags.json?&quot;json&quot;:&quot;message&quot;,data:f};if(&quot;function&quot;==typeof e){g.id=++this.ackPackets;g.ack=true;this.acks[g.id]=e}return this.packet(g)};b.prototype.emit=function(f){var e=Array.prototype.slice.call(arguments,1),h=e[e.length-1],g={type:&quot;event&quot;,name:f};if(&quot;function&quot;==typeof h){g.id=++this.ackPackets;g.ack=&quot;data&quot;;this.acks[g.id]=h;e=e.slice(0,e.length-1)}g.args=e;return this.packet(g)};b.prototype.disconnect=function(){if(this.name===&quot;&quot;){this.socket.disconnect()}else{this.packet({type:&quot;disconnect&quot;});this.$emit(&quot;disconnect&quot;)}return this};b.prototype.onPacket=function(f){var e=this;function h(){e.packet({type:&quot;ack&quot;,args:d.util.toArray(arguments),ackId:f.id})}switch(f.type){case&quot;connect&quot;:this.$emit(&quot;connect&quot;);break;case&quot;disconnect&quot;:if(this.name===&quot;&quot;){this.socket.onDisconnect(f.reason||&quot;booted&quot;)}else{this.$emit(&quot;disconnect&quot;,f.reason)}break;case&quot;message&quot;:case&quot;json&quot;:var g=[&quot;message&quot;,f.data];if(f.ack==&quot;data&quot;){g.push(h)}else{if(f.ack){this.packet({type:&quot;ack&quot;,ackId:f.id})}}this.$emit.apply(this,g);break;case&quot;event&quot;:var g=[f.name].concat(f.args);if(f.ack==&quot;data&quot;){g.push(h)}this.$emit.apply(this,g);break;case&quot;ack&quot;:if(this.acks[f.ackId]){this.acks[f.ackId].apply(this,f.args);delete this.acks[f.ackId]}break;case&quot;error&quot;:if(f.advice){this.socket.onError(f)}else{if(f.reason==&quot;unauthorized&quot;){this.$emit(&quot;connect_failed&quot;,f.reason)}else{this.$emit(&quot;error&quot;,f.reason)}}break}};function c(f,e){this.namespace=f;this.name=e}c.prototype.send=function(){this.namespace.flags[this.name]=true;this.namespace.send.apply(this.namespace,arguments)};c.prototype.emit=function(){this.namespace.flags[this.name]=true;this.namespace.emit.apply(this.namespace,arguments)}})(&quot;undefined&quot;!=typeof io?io:module.exports,&quot;undefined&quot;!=typeof io?io:module.parent.exports);(function(b,d,c){b.websocket=a;function a(e){d.Transport.apply(this,arguments)}d.util.inherit(a,d.Transport);a.prototype.name=&quot;websocket&quot;;a.prototype.open=function(){var g=d.util.query(this.socket.options.query),f=this,e;if(!e){e=c.MozWebSocket||c.WebSocket}this.websocket=new e(this.prepareUrl()+g);this.websocket.onopen=function(){f.onOpen();f.socket.setBuffer(false)};this.websocket.onmessage=function(h){f.onData(h.data)};this.websocket.onclose=function(){f.onClose();f.socket.setBuffer(true)};this.websocket.onerror=function(h){f.onError(h)};return this};a.prototype.send=function(e){this.websocket.send(e);return this};a.prototype.payload=function(e){for(var g=0,f=e.length;g&lt;f;g++){this.packet(e[g])}return this};a.prototype.close=function(){this.websocket.close();return this};a.prototype.onError=function(f){this.socket.onError(f)};a.prototype.scheme=function(){return this.socket.options.secure?&quot;wss&quot;:&quot;ws&quot;};a.check=function(){return(&quot;WebSocket&quot; in c&amp;&amp;!(&quot;__addTask&quot; in WebSocket))||&quot;MozWebSocket&quot; in c};a.xdomainCheck=function(){return true};d.transports.push(&quot;websocket&quot;)})(&quot;undefined&quot;!=typeof io?io.Transport:module.exports,&quot;undefined&quot;!=typeof io?io:module.parent.exports,this);(function(a,e,c){a.XHR=b;function b(f){if(!f){return}e.Transport.apply(this,arguments);this.sendBuffer=[]}e.util.inherit(b,e.Transport);b.prototype.open=function(){this.socket.setBuffer(false);this.onOpen();this.get();this.setCloseTimeout();return this};b.prototype.payload=function(j){var h=[];for(var g=0,f=j.length;g&lt;f;g++){h.push(e.parser.encodePacket(j[g]))}this.send(e.parser.encodePayload(h))};b.prototype.send=function(f){this.post(f);return this};function d(){}b.prototype.post=function(h){var g=this;this.socket.setBuffer(true);function f(){if(this.readyState==4){this.onreadystatechange=d;g.posting=false;if(this.status==200){g.socket.setBuffer(false)}else{g.onClose()}}}function i(){this.onload=d;g.socket.setBuffer(false)}this.sendXHR=this.request(&quot;POST&quot;);if(c.XDomainRequest&amp;&amp;this.sendXHR instanceof XDomainRequest){this.sendXHR.onload=this.sendXHR.onerror=i}else{this.sendXHR.onreadystatechange=f}this.sendXHR.send(h)};b.prototype.close=function(){this.onClose();return this};b.prototype.request=function(i){var f=e.util.request(this.socket.isXDomain()),g=e.util.query(this.socket.options.query,&quot;t=&quot;+ +new Date);f.open(i||&quot;GET&quot;,this.prepareUrl()+g,true);if(i==&quot;POST&quot;){try{if(f.setRequestHeader){f.setRequestHeader(&quot;Content-type&quot;,&quot;text/plain;charset=UTF-8&quot;)}else{f.contentType=&quot;text/plain&quot;}}catch(h){}}return f};b.prototype.scheme=function(){return this.socket.options.secure?&quot;https&quot;:&quot;http&quot;};b.check=function(f,g){try{if(e.util.request(g)){return true}}catch(h){}return false};b.xdomainCheck=function(){return b.check(null,true)}})(&quot;undefined&quot;!=typeof io?io.Transport:module.exports,&quot;undefined&quot;!=typeof io?io:module.parent.exports,this);(function(a,c){a.htmlfile=b;function b(d){c.Transport.XHR.apply(this,arguments)}c.util.inherit(b,c.Transport.XHR);b.prototype.name=&quot;htmlfile&quot;;b.prototype.get=function(){this.doc=new ActiveXObject(&quot;htmlfile&quot;);this.doc.open();this.doc.write(&quot;&lt;html&gt;&lt;/html&gt;&quot;);this.doc.close();this.doc.parentWindow.s=this;var d=this.doc.createElement(&quot;div&quot;);d.className=&quot;socketio&quot;;this.doc.body.appendChild(d);this.iframe=this.doc.createElement(&quot;iframe&quot;);d.appendChild(this.iframe);var e=this,f=c.util.query(this.socket.options.query,&quot;t=&quot;+ +new Date);this.iframe.src=this.prepareUrl()+f;c.util.on(window,&quot;unload&quot;,function(){e.destroy()})};b.prototype._=function(f,h){this.onData(f);try{var d=h.getElementsByTagName(&quot;script&quot;)[0];d.parentNode.removeChild(d)}catch(g){}};b.prototype.destroy=function(){if(this.iframe){try{this.iframe.src=&quot;about:blank&quot;}catch(d){}this.doc=null;this.iframe.parentNode.removeChild(this.iframe);this.iframe=null;CollectGarbage()}};b.prototype.close=function(){this.destroy();return c.Transport.XHR.prototype.close.call(this)};b.check=function(){if(&quot;ActiveXObject&quot; in window){try{var d=new ActiveXObject(&quot;htmlfile&quot;);return d&amp;&amp;c.Transport.XHR.check()}catch(f){}}return false};b.xdomainCheck=function(){return false};c.transports.push(&quot;htmlfile&quot;)})(&quot;undefined&quot;!=typeof io?io.Transport:module.exports,&quot;undefined&quot;!=typeof io?io:module.parent.exports);(function(a,e,b){a[&quot;xhr-polling&quot;]=d;function d(){e.Transport.XHR.apply(this,arguments)}e.util.inherit(d,e.Transport.XHR);e.util.merge(d,e.Transport.XHR);d.prototype.name=&quot;xhr-polling&quot;;d.prototype.open=function(){var f=this;e.Transport.XHR.prototype.open.call(f);return false};function c(){}d.prototype.get=function(){if(!this.open){return}var g=this;function f(){if(this.readyState==4){this.onreadystatechange=c;if(this.status==200){g.onData(this.responseText);g.get()}else{g.onClose()}}}function h(){this.onload=c;g.onData(this.responseText);g.get()}this.xhr=this.request();if(b.XDomainRequest&amp;&amp;this.xhr instanceof XDomainRequest){this.xhr.onload=this.xhr.onerror=h}else{this.xhr.onreadystatechange=f}this.xhr.send(null)};d.prototype.onClose=function(){e.Transport.XHR.prototype.onClose.call(this);if(this.xhr){this.xhr.onreadystatechange=this.xhr.onload=c;try{this.xhr.abort()}catch(f){}this.xhr=null}};d.prototype.ready=function(f,h){var g=this;e.util.defer(function(){h.call(g)})};e.transports.push(&quot;xhr-polling&quot;)})(&quot;undefined&quot;!=typeof io?io.Transport:module.exports,&quot;undefined&quot;!=typeof io?io:module.parent.exports,this);(function(b,e,d){var a=d.document&amp;&amp;&quot;MozAppearance&quot; in d.document.documentElement.style;b[&quot;jsonp-polling&quot;]=c;function c(f){e.Transport[&quot;xhr-polling&quot;].apply(this,arguments);this.index=e.j.length;var g=this;e.j.push(function(h){g._(h)})}e.util.inherit(c,e.Transport[&quot;xhr-polling&quot;]);c.prototype.name=&quot;jsonp-polling&quot;;c.prototype.post=function(l){var o=this,n=e.util.query(this.socket.options.query,&quot;t=&quot;+(+new Date)+&quot;&amp;i=&quot;+this.index);if(!this.form){var g=document.createElement(&quot;form&quot;),h=document.createElement(&quot;textarea&quot;),f=this.iframeId=&quot;socketio_iframe_&quot;+this.index,k;g.className=&quot;socketio&quot;;g.style.position=&quot;absolute&quot;;g.style.top=&quot;-1000px&quot;;g.style.left=&quot;-1000px&quot;;g.target=f;g.method=&quot;POST&quot;;g.setAttribute(&quot;accept-charset&quot;,&quot;utf-8&quot;);h.name=&quot;d&quot;;g.appendChild(h);document.body.appendChild(g);this.form=g;this.area=h}this.form.action=this.prepareUrl()+n;function i(){j();o.socket.setBuffer(false)}function j(){if(o.iframe){o.form.removeChild(o.iframe)}try{k=document.createElement('&lt;iframe name=&quot;'+o.iframeId+'&quot;&gt;')}catch(p){k=document.createElement(&quot;iframe&quot;);k.name=o.iframeId}k.id=o.iframeId;o.form.appendChild(k);o.iframe=k}j();this.area.value=e.JSON.stringify(l);try{this.form.submit()}catch(m){}if(this.iframe.attachEvent){k.onreadystatechange=function(){if(o.iframe.readyState==&quot;complete&quot;){i()}}}else{this.iframe.onload=i}this.socket.setBuffer(true)};c.prototype.get=function(){var g=this,f=document.createElement(&quot;script&quot;),i=e.util.query(this.socket.options.query,&quot;t=&quot;+(+new Date)+&quot;&amp;i=&quot;+this.index);if(this.script){this.script.parentNode.removeChild(this.script);this.script=null}f.async=true;f.src=this.prepareUrl()+i;f.onerror=function(){g.onClose()};var h=document.getElementsByTagName(&quot;script&quot;)[0];h.parentNode.insertBefore(f,h);this.script=f;if(a){setTimeout(function(){var j=document.createElement(&quot;iframe&quot;);document.body.appendChild(j);document.body.removeChild(j)},100)}};c.prototype._=function(f){this.onData(f);if(this.open){this.get()}return this};c.prototype.ready=function(f,h){var g=this;if(!a){return h.call(this)}e.util.load(function(){h.call(g)})};c.check=function(){return&quot;document&quot; in d};c.xdomainCheck=function(){return true};e.transports.push(&quot;jsonp-polling&quot;)})(&quot;undefined&quot;!=typeof io?io.Transport:module.exports,&quot;undefined&quot;!=typeof io?io:module.parent.exports,this);var Juggernaut=function(a){this.options=a||{};this.options.host=this.options.host||window.location.hostname;this.options.port=this.options.port||8080;this.handlers={};this.meta=this.options.meta;this.io=io.connect(this.options.host,this.options);this.io.on(&quot;connect&quot;,this.proxy(this.onconnect));this.io.on(&quot;message&quot;,this.proxy(this.onmessage));this.io.on(&quot;disconnect&quot;,this.proxy(this.ondisconnect));this.on(&quot;connect&quot;,this.proxy(this.writeMeta))};Juggernaut.fn=Juggernaut.prototype;Juggernaut.fn.proxy=function(b){var a=this;return(function(){return b.apply(a,arguments)})};Juggernaut.fn.on=function(a,b){if(!a||!b){return}if(!this.handlers[a]){this.handlers[a]=[]}this.handlers[a].push(b)};Juggernaut.fn.bind=Juggernaut.fn.on;Juggernaut.fn.unbind=function(a){if(!this.handlers){return}delete this.handlers[a]};Juggernaut.fn.write=function(a){if(typeof a.toJSON==&quot;function&quot;){a=a.toJSON()}this.io.send(a)};Juggernaut.fn.subscribe=function(b,c){if(!b){throw&quot;Must provide a channel&quot;}this.on(b+&quot;:data&quot;,c);var a=this.proxy(function(){var d=new Juggernaut.Message;d.type=&quot;subscribe&quot;;d.channel=b;this.write(d)});if(this.io.socket.connected){a()}else{this.on(&quot;connect&quot;,a)}};Juggernaut.fn.unsubscribe=function(b){if(!b){throw&quot;Must provide a channel&quot;}this.unbind(b+&quot;:data&quot;);var a=new Juggernaut.Message;a.type=&quot;unsubscribe&quot;;a.channel=b;this.write(a)};Juggernaut.fn.trigger=function(){var c=[];for(var g=0;g&lt;arguments.length;g++){c.push(arguments[g])}var b=c.shift();var e=this.handlers[b];if(!e){return}for(var d=0,a=e.length;d&lt;a;d++){e[d].apply(this,c)}};Juggernaut.fn.writeMeta=function(){if(!this.meta){return}var a=new Juggernaut.Message;a.type=&quot;meta&quot;;a.data=this.meta;this.write(a)};Juggernaut.fn.onconnect=function(){this.sessionID=this.io.socket.sessionid;this.trigger(&quot;connect&quot;)};Juggernaut.fn.ondisconnect=function(){this.trigger(&quot;disconnect&quot;)};Juggernaut.fn.onmessage=function(b){var a=Juggernaut.Message.fromJSON(b);this.trigger(&quot;message&quot;,a);this.trigger(&quot;data&quot;,a.channel,a.data);this.trigger(a.channel+&quot;:data&quot;,a.data)};Juggernaut.Message=function(b){for(var a in b){this[a]=b[a]}};Juggernaut.Message.fromJSON=function(a){return(new this(JSON.parse(a)))};Juggernaut.Message.prototype.toJSON=function(){var a={};for(var b in this){if(typeof this[b]!=&quot;function&quot;){a[b]=this[b]}}return(JSON.stringify(a))};if(typeof module!=&quot;undefined&quot;){module.exports=Juggernaut}else{window.Juggernaut=Juggernaut};</div></pre></div>
          </td>
        </tr>
      </table>
  </div>

          </div>
        </div>
      </div>
    </div>

  </div>

<div class="frame frame-loading" style="display:none;" data-tree-list-url="/maccman/juggernaut/tree-list/fe672b36c14ac5ed53cfd4105cfc2577d4300d6b" data-blob-url-prefix="/maccman/juggernaut/blob/fe672b36c14ac5ed53cfd4105cfc2577d4300d6b">
  <img src="https://a248.e.akamai.net/assets.github.com/images/modules/ajax/big_spinner_336699.gif" height="32" width="32">
</div>

    </div>

    </div>

    <!-- footer -->
    <div id="footer" >
      
  <div class="upper_footer">
     <div class="site" class="clearfix">

       <!--[if IE]><h4 id="blacktocat_ie">GitHub Links</h4><![endif]-->
       <![if !IE]><h4 id="blacktocat">GitHub Links</h4><![endif]>

       <ul class="footer_nav">
         <h4>GitHub</h4>
         <li><a href="https://github.com/about">About</a></li>
         <li><a href="https://github.com/blog">Blog</a></li>
         <li><a href="https://github.com/features">Features</a></li>
         <li><a href="https://github.com/contact">Contact &amp; Support</a></li>
         <li><a href="https://github.com/training">Training</a></li>
         <li><a href="http://status.github.com/">Site Status</a></li>
       </ul>

       <ul class="footer_nav">
         <h4>Tools</h4>
         <li><a href="http://mac.github.com/">GitHub for Mac</a></li>
         <li><a href="http://mobile.github.com/">Issues for iPhone</a></li>
         <li><a href="https://gist.github.com">Gist: Code Snippets</a></li>
         <li><a href="http://enterprise.github.com/">GitHub Enterprise</a></li>
         <li><a href="http://jobs.github.com/">Job Board</a></li>
       </ul>

       <ul class="footer_nav">
         <h4>Extras</h4>
         <li><a href="http://shop.github.com/">GitHub Shop</a></li>
         <li><a href="http://octodex.github.com/">The Octodex</a></li>
       </ul>

       <ul class="footer_nav">
         <h4>Documentation</h4>
         <li><a href="http://help.github.com/">GitHub Help</a></li>
         <li><a href="http://developer.github.com/">Developer API</a></li>
         <li><a href="http://github.github.com/github-flavored-markdown/">GitHub Flavored Markdown</a></li>
         <li><a href="http://pages.github.com/">GitHub Pages</a></li>
       </ul>

     </div><!-- /.site -->
  </div><!-- /.upper_footer -->

<div class="lower_footer">
  <div class="site" class="clearfix">
    <!--[if IE]><div id="legal_ie"><![endif]-->
    <![if !IE]><div id="legal"><![endif]>
      <ul>
          <li><a href="https://github.com/site/terms">Terms of Service</a></li>
          <li><a href="https://github.com/site/privacy">Privacy</a></li>
          <li><a href="https://github.com/security">Security</a></li>
      </ul>

      <p>&copy; 2011 <span id="_rrt" title="0.08808s from fe4.rs.github.com">GitHub</span> Inc. All rights reserved.</p>
    </div><!-- /#legal or /#legal_ie-->

      <div class="sponsor">
        <a href="http://www.rackspace.com" class="logo">
          <img alt="Dedicated Server" height="36" src="https://a248.e.akamai.net/assets.github.com/images/modules/footer/rackspace_logo.png?v2" width="38" />
        </a>
        Powered by the <a href="http://www.rackspace.com ">Dedicated
        Servers</a> and<br/> <a href="http://www.rackspacecloud.com">Cloud
        Computing</a> of Rackspace Hosting<span>&reg;</span>
      </div>
  </div><!-- /.site -->
</div><!-- /.lower_footer -->

    </div><!-- /#footer -->

    

<div id="keyboard_shortcuts_pane" class="instapaper_ignore readability-extra" style="display:none">
  <h2>Keyboard Shortcuts <small><a href="#" class="js-see-all-keyboard-shortcuts">(see all)</a></small></h2>

  <div class="columns threecols">
    <div class="column first">
      <h3>Site wide shortcuts</h3>
      <dl class="keyboard-mappings">
        <dt>s</dt>
        <dd>Focus site search</dd>
      </dl>
      <dl class="keyboard-mappings">
        <dt>?</dt>
        <dd>Bring up this help dialog</dd>
      </dl>
    </div><!-- /.column.first -->

    <div class="column middle" style=&#39;display:none&#39;>
      <h3>Commit list</h3>
      <dl class="keyboard-mappings">
        <dt>j</dt>
        <dd>Move selection down</dd>
      </dl>
      <dl class="keyboard-mappings">
        <dt>k</dt>
        <dd>Move selection up</dd>
      </dl>
      <dl class="keyboard-mappings">
        <dt>c <em>or</em> o <em>or</em> enter</dt>
        <dd>Open commit</dd>
      </dl>
      <dl class="keyboard-mappings">
        <dt>y</dt>
        <dd>Expand URL to its canonical form</dd>
      </dl>
    </div><!-- /.column.first -->

    <div class="column last" style=&#39;display:none&#39;>
      <h3>Pull request list</h3>
      <dl class="keyboard-mappings">
        <dt>j</dt>
        <dd>Move selection down</dd>
      </dl>
      <dl class="keyboard-mappings">
        <dt>k</dt>
        <dd>Move selection up</dd>
      </dl>
      <dl class="keyboard-mappings">
        <dt>o <em>or</em> enter</dt>
        <dd>Open issue</dd>
      </dl>
    </div><!-- /.columns.last -->

  </div><!-- /.columns.equacols -->

  <div style=&#39;display:none&#39;>
    <div class="rule"></div>

    <h3>Issues</h3>

    <div class="columns threecols">
      <div class="column first">
        <dl class="keyboard-mappings">
          <dt>j</dt>
          <dd>Move selection down</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>k</dt>
          <dd>Move selection up</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>x</dt>
          <dd>Toggle selection</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>o <em>or</em> enter</dt>
          <dd>Open issue</dd>
        </dl>
      </div><!-- /.column.first -->
      <div class="column middle">
        <dl class="keyboard-mappings">
          <dt>I</dt>
          <dd>Mark selection as read</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>U</dt>
          <dd>Mark selection as unread</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>e</dt>
          <dd>Close selection</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>y</dt>
          <dd>Remove selection from view</dd>
        </dl>
      </div><!-- /.column.middle -->
      <div class="column last">
        <dl class="keyboard-mappings">
          <dt>c</dt>
          <dd>Create issue</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>l</dt>
          <dd>Create label</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>i</dt>
          <dd>Back to inbox</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>u</dt>
          <dd>Back to issues</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>/</dt>
          <dd>Focus issues search</dd>
        </dl>
      </div>
    </div>
  </div>

  <div style=&#39;display:none&#39;>
    <div class="rule"></div>

    <h3>Issues Dashboard</h3>

    <div class="columns threecols">
      <div class="column first">
        <dl class="keyboard-mappings">
          <dt>j</dt>
          <dd>Move selection down</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>k</dt>
          <dd>Move selection up</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>o <em>or</em> enter</dt>
          <dd>Open issue</dd>
        </dl>
      </div><!-- /.column.first -->
    </div>
  </div>

  <div style=&#39;display:none&#39;>
    <div class="rule"></div>

    <h3>Network Graph</h3>
    <div class="columns equacols">
      <div class="column first">
        <dl class="keyboard-mappings">
          <dt><span class="badmono">←</span> <em>or</em> h</dt>
          <dd>Scroll left</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt><span class="badmono">→</span> <em>or</em> l</dt>
          <dd>Scroll right</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt><span class="badmono">↑</span> <em>or</em> k</dt>
          <dd>Scroll up</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt><span class="badmono">↓</span> <em>or</em> j</dt>
          <dd>Scroll down</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>t</dt>
          <dd>Toggle visibility of head labels</dd>
        </dl>
      </div><!-- /.column.first -->
      <div class="column last">
        <dl class="keyboard-mappings">
          <dt>shift <span class="badmono">←</span> <em>or</em> shift h</dt>
          <dd>Scroll all the way left</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>shift <span class="badmono">→</span> <em>or</em> shift l</dt>
          <dd>Scroll all the way right</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>shift <span class="badmono">↑</span> <em>or</em> shift k</dt>
          <dd>Scroll all the way up</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>shift <span class="badmono">↓</span> <em>or</em> shift j</dt>
          <dd>Scroll all the way down</dd>
        </dl>
      </div><!-- /.column.last -->
    </div>
  </div>

  <div >
    <div class="rule"></div>
    <div class="columns threecols">
      <div class="column first" >
        <h3>Source Code Browsing</h3>
        <dl class="keyboard-mappings">
          <dt>t</dt>
          <dd>Activates the file finder</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>l</dt>
          <dd>Jump to line</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>w</dt>
          <dd>Switch branch/tag</dd>
        </dl>
        <dl class="keyboard-mappings">
          <dt>y</dt>
          <dd>Expand URL to its canonical form</dd>
        </dl>
      </div>
    </div>
  </div>
</div>

    <div id="markdown-help" class="instapaper_ignore readability-extra">
  <h2>Markdown Cheat Sheet</h2>

  <div class="cheatsheet-content">

  <div class="mod">
    <div class="col">
      <h3>Format Text</h3>
      <p>Headers</p>
      <pre>
# This is an &lt;h1&gt; tag
## This is an &lt;h2&gt; tag
###### This is an &lt;h6&gt; tag</pre>
     <p>Text styles</p>
     <pre>
*This text will be italic*
_This will also be italic_
**This text will be bold**
__This will also be bold__

*You **can** combine them*
</pre>
    </div>
    <div class="col">
      <h3>Lists</h3>
      <p>Unordered</p>
      <pre>
* Item 1
* Item 2
  * Item 2a
  * Item 2b</pre>
     <p>Ordered</p>
     <pre>
1. Item 1
2. Item 2
3. Item 3
   * Item 3a
   * Item 3b</pre>
    </div>
    <div class="col">
      <h3>Miscellaneous</h3>
      <p>Images</p>
      <pre>
![GitHub Logo](/images/logo.png)
Format: ![Alt Text](url)
</pre>
     <p>Links</p>
     <pre>
http://github.com - automatic!
[GitHub](http://github.com)</pre>
<p>Blockquotes</p>
     <pre>
As Kanye West said:
> We're living the future so
> the present is our past.
</pre>
    </div>
  </div>
  <div class="rule"></div>

  <h3>Code Examples in Markdown</h3>
  <div class="col">
      <p>Syntax highlighting with <a href="http://github.github.com/github-flavored-markdown/" title="GitHub Flavored Markdown" target="_blank">GFM</a></p>
      <pre>
```javascript
function fancyAlert(arg) {
  if(arg) {
    $.facebox({div:'#foo'})
  }
}
```</pre>
    </div>
    <div class="col">
      <p>Or, indent your code 4 spaces</p>
      <pre>
Here is a Python code example
without syntax highlighting:

    def foo:
      if not bar:
        return true</pre>
    </div>
    <div class="col">
      <p>Inline code for comments</p>
      <pre>
I think you should use an
`&lt;addr&gt;` element here instead.</pre>
    </div>
  </div>

  </div>
</div>

    <div class="context-overlay"></div>

    <div class="ajax-error-message">
      <p><span class="icon"></span> Something went wrong with that request. Please try again. <a href="javascript:;" class="ajax-error-dismiss">Dismiss</a></p>
    </div>

    
    
    
  </body>
</html>

