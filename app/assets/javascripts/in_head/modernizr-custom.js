/*! modernizr 3.6.0 (Custom Build) | MIT *
 * https://modernizr.com/download/?-csstransforms-csstransforms3d-csstransitions-hidden-inlinesvg-input-inputtypes-domprefixes-prefixed-prefixes-setclasses-shiv-testallprops-testprop !*/
!function(e,t,n){function r(e,t){return typeof e===t}function i(){var e,t,n,i,a,o,s;for(var l in S)if(S.hasOwnProperty(l)){if(e=[],t=S[l],t.name&&(e.push(t.name.toLowerCase()),t.options&&t.options.aliases&&t.options.aliases.length))for(n=0;n<t.options.aliases.length;n++)e.push(t.options.aliases[n].toLowerCase());for(i=r(t.fn,"function")?t.fn():t.fn,a=0;a<e.length;a++)o=e[a],s=o.split("."),1===s.length?Modernizr[s[0]]=i:(!Modernizr[s[0]]||Modernizr[s[0]]instanceof Boolean||(Modernizr[s[0]]=new Boolean(Modernizr[s[0]])),Modernizr[s[0]][s[1]]=i),C.push((i?"":"no-")+s.join("-"))}}function a(e){var t=E.className,n=Modernizr._config.classPrefix||"";if(w&&(t=t.baseVal),Modernizr._config.enableJSClass){var r=new RegExp("(^|\\s)"+n+"no-js(\\s|$)");t=t.replace(r,"$1"+n+"js$2")}Modernizr._config.enableClasses&&(t+=" "+n+e.join(" "+n),w?E.className.baseVal=t:E.className=t)}function o(e){return e.replace(/([a-z])-([a-z])/g,function(e,t,n){return t+n.toUpperCase()}).replace(/^-/,"")}function s(){return"function"!=typeof t.createElement?t.createElement(arguments[0]):w?t.createElementNS.call(t,"http://www.w3.org/2000/svg",arguments[0]):t.createElement.apply(t,arguments)}function l(e,t){return!!~(""+e).indexOf(t)}function u(e,t){return function(){return e.apply(t,arguments)}}function c(e,t,n){var i;for(var a in e)if(e[a]in t)return n===!1?e[a]:(i=t[e[a]],r(i,"function")?u(i,n||t):i);return!1}function f(e){return e.replace(/([A-Z])/g,function(e,t){return"-"+t.toLowerCase()}).replace(/^ms-/,"-ms-")}function d(t,n,r){var i;if("getComputedStyle"in e){i=getComputedStyle.call(e,t,n);var a=e.console;if(null!==i)r&&(i=i.getPropertyValue(r));else if(a){var o=a.error?"error":"log";a[o].call(a,"getComputedStyle returning null, its possible modernizr test results are inaccurate")}}else i=!n&&t.currentStyle&&t.currentStyle[r];return i}function p(){var e=t.body;return e||(e=s(w?"svg":"body"),e.fake=!0),e}function m(e,n,r,i){var a,o,l,u,c="modernizr",f=s("div"),d=p();if(parseInt(r,10))for(;r--;)l=s("div"),l.id=i?i[r]:c+(r+1),f.appendChild(l);return a=s("style"),a.type="text/css",a.id="s"+c,(d.fake?d:f).appendChild(a),d.appendChild(f),a.styleSheet?a.styleSheet.cssText=e:a.appendChild(t.createTextNode(e)),f.id=c,d.fake&&(d.style.background="",d.style.overflow="hidden",u=E.style.overflow,E.style.overflow="hidden",E.appendChild(d)),o=n(f,e),d.fake?(d.parentNode.removeChild(d),E.style.overflow=u,E.offsetHeight):f.parentNode.removeChild(f),!!o}function h(t,r){var i=t.length;if("CSS"in e&&"supports"in e.CSS){for(;i--;)if(e.CSS.supports(f(t[i]),r))return!0;return!1}if("CSSSupportsRule"in e){for(var a=[];i--;)a.push("("+f(t[i])+":"+r+")");return a=a.join(" or "),m("@supports ("+a+") { #modernizr { position: absolute; } }",function(e){return"absolute"==d(e,null,"position")})}return n}function v(e,t,i,a){function u(){f&&(delete R.style,delete R.modElem)}if(a=r(a,"undefined")?!1:a,!r(i,"undefined")){var c=h(e,i);if(!r(c,"undefined"))return c}for(var f,d,p,m,v,g=["modernizr","tspan","samp"];!R.style&&g.length;)f=!0,R.modElem=s(g.shift()),R.style=R.modElem.style;for(p=e.length,d=0;p>d;d++)if(m=e[d],v=R.style[m],l(m,"-")&&(m=o(m)),R.style[m]!==n){if(a||r(i,"undefined"))return u(),"pfx"==t?m:!0;try{R.style[m]=i}catch(y){}if(R.style[m]!=v)return u(),"pfx"==t?m:!0}return u(),!1}function g(e,t,n,i,a){var o=e.charAt(0).toUpperCase()+e.slice(1),s=(e+" "+F.join(o+" ")+o).split(" ");return r(t,"string")||r(t,"undefined")?v(s,t,i,a):(s=(e+" "+T.join(o+" ")+o).split(" "),c(s,t,n))}function y(e,t,r){return g(e,n,n,t,r)}var C=[],S=[],b={_version:"3.6.0",_config:{classPrefix:"",enableClasses:!0,enableJSClass:!0,usePrefixes:!0},_q:[],on:function(e,t){var n=this;setTimeout(function(){t(n[e])},0)},addTest:function(e,t,n){S.push({name:e,fn:t,options:n})},addAsyncTest:function(e){S.push({name:null,fn:e})}},Modernizr=function(){};Modernizr.prototype=b,Modernizr=new Modernizr;var x=b._config.usePrefixes?" -webkit- -moz- -o- -ms- ".split(" "):["",""];b._prefixes=x;var E=t.documentElement,w="svg"===E.nodeName.toLowerCase();w||!function(e,t){function n(e,t){var n=e.createElement("p"),r=e.getElementsByTagName("head")[0]||e.documentElement;return n.innerHTML="x<style>"+t+"</style>",r.insertBefore(n.lastChild,r.firstChild)}function r(){var e=C.elements;return"string"==typeof e?e.split(" "):e}function i(e,t){var n=C.elements;"string"!=typeof n&&(n=n.join(" ")),"string"!=typeof e&&(e=e.join(" ")),C.elements=n+" "+e,u(t)}function a(e){var t=y[e[v]];return t||(t={},g++,e[v]=g,y[g]=t),t}function o(e,n,r){if(n||(n=t),f)return n.createElement(e);r||(r=a(n));var i;return i=r.cache[e]?r.cache[e].cloneNode():h.test(e)?(r.cache[e]=r.createElem(e)).cloneNode():r.createElem(e),!i.canHaveChildren||m.test(e)||i.tagUrn?i:r.frag.appendChild(i)}function s(e,n){if(e||(e=t),f)return e.createDocumentFragment();n=n||a(e);for(var i=n.frag.cloneNode(),o=0,s=r(),l=s.length;l>o;o++)i.createElement(s[o]);return i}function l(e,t){t.cache||(t.cache={},t.createElem=e.createElement,t.createFrag=e.createDocumentFragment,t.frag=t.createFrag()),e.createElement=function(n){return C.shivMethods?o(n,e,t):t.createElem(n)},e.createDocumentFragment=Function("h,f","return function(){var n=f.cloneNode(),c=n.createElement;h.shivMethods&&("+r().join().replace(/[\w\-:]+/g,function(e){return t.createElem(e),t.frag.createElement(e),'c("'+e+'")'})+");return n}")(C,t.frag)}function u(e){e||(e=t);var r=a(e);return!C.shivCSS||c||r.hasCSS||(r.hasCSS=!!n(e,"article,aside,dialog,figcaption,figure,footer,header,hgroup,main,nav,section{display:block}mark{background:#FF0;color:#000}template{display:none}")),f||l(e,r),e}var c,f,d="3.7.3",p=e.html5||{},m=/^<|^(?:button|map|select|textarea|object|iframe|option|optgroup)$/i,h=/^(?:a|b|code|div|fieldset|h1|h2|h3|h4|h5|h6|i|label|li|ol|p|q|span|strong|style|table|tbody|td|th|tr|ul)$/i,v="_html5shiv",g=0,y={};!function(){try{var e=t.createElement("a");e.innerHTML="<xyz></xyz>",c="hidden"in e,f=1==e.childNodes.length||function(){t.createElement("a");var e=t.createDocumentFragment();return"undefined"==typeof e.cloneNode||"undefined"==typeof e.createDocumentFragment||"undefined"==typeof e.createElement}()}catch(n){c=!0,f=!0}}();var C={elements:p.elements||"abbr article aside audio bdi canvas data datalist details dialog figcaption figure footer header hgroup main mark meter nav output picture progress section summary template time video",version:d,shivCSS:p.shivCSS!==!1,supportsUnknownElements:f,shivMethods:p.shivMethods!==!1,type:"default",shivDocument:u,createElement:o,createDocumentFragment:s,addElements:i};e.html5=C,u(t),"object"==typeof module&&module.exports&&(module.exports=C)}("undefined"!=typeof e?e:this,t);var _="Moz O ms Webkit",T=b._config.usePrefixes?_.toLowerCase().split(" "):[];b._domPrefixes=T,Modernizr.addTest("hidden","hidden"in s("a"));var k=s("input"),N="autocomplete autofocus list placeholder max min multiple pattern required step".split(" "),z={};Modernizr.input=function(t){for(var n=0,r=t.length;r>n;n++)z[t[n]]=!!(t[n]in k);return z.list&&(z.list=!(!s("datalist")||!e.HTMLDataListElement)),z}(N);var P="search tel url email datetime date month week time datetime-local number range color".split(" "),j={};Modernizr.inputtypes=function(e){for(var r,i,a,o=e.length,s="1)",l=0;o>l;l++)k.setAttribute("type",r=e[l]),a="text"!==k.type&&"style"in k,a&&(k.value=s,k.style.cssText="position:absolute;visibility:hidden;",/^range$/.test(r)&&k.style.WebkitAppearance!==n?(E.appendChild(k),i=t.defaultView,a=i.getComputedStyle&&"textfield"!==i.getComputedStyle(k,null).WebkitAppearance&&0!==k.offsetHeight,E.removeChild(k)):/^(search|tel)$/.test(r)||(a=/^(url|email)$/.test(r)?k.checkValidity&&k.checkValidity()===!1:k.value!=s)),j[e[l]]=!!a;return j}(P);var L="CSS"in e&&"supports"in e.CSS,A="supportsCSS"in e;Modernizr.addTest("supports",L||A);var F=b._config.usePrefixes?_.split(" "):[];b._cssomPrefixes=F;var M=function(t){var r,i=x.length,a=e.CSSRule;if("undefined"==typeof a)return n;if(!t)return!1;if(t=t.replace(/^@/,""),r=t.replace(/-/g,"_").toUpperCase()+"_RULE",r in a)return"@"+t;for(var o=0;i>o;o++){var s=x[o],l=s.toUpperCase()+"_"+r;if(l in a)return"@-"+s.toLowerCase()+"-"+t}return!1};b.atRule=M;var D={elem:s("modernizr")};Modernizr._q.push(function(){delete D.elem});var R={style:D.elem.style};Modernizr._q.unshift(function(){delete R.style}),Modernizr.addTest("inlinesvg",function(){var e=s("div");return e.innerHTML="<svg/>","http://www.w3.org/2000/svg"==("undefined"!=typeof SVGRect&&e.firstChild&&e.firstChild.namespaceURI)});b.testProp=function(e,t,r){return v([e],n,t,r)};b.testAllProps=g;b.prefixed=function(e,t,n){return 0===e.indexOf("@")?M(e):(-1!=e.indexOf("-")&&(e=o(e)),t?g(e,t,n):g(e,"pfx"))};b.testAllProps=y,Modernizr.addTest("csstransforms",function(){return-1===navigator.userAgent.indexOf("Android 2.")&&y("transform","scale(1)",!0)}),Modernizr.addTest("csstransforms3d",function(){return!!y("perspective","1px",!0)}),Modernizr.addTest("csstransitions",y("transition","all",!0)),i(),a(C),delete b.addTest,delete b.addAsyncTest;for(var U=0;U<Modernizr._q.length;U++)Modernizr._q[U]();e.Modernizr=Modernizr}(window,document);