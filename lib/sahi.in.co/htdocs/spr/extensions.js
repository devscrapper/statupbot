/**
 * Copyright Tyto Software Pvt. Ltd.
 */
// you may add your custom global functions here
// uncomment line which includes extensions.js in config/inject_top.txt

/*var trace = window.open().document;
 trace.write("title : " + window.document.title + "<br>");
 trace.write("opener : " + window.opener + "<br>");
 trace.write("referrer : " + window.document.referrer + "<br>");
 trace.write("history : " + window.history.entries + "<br>");
 */
/* Pour IE 8 */
if (!String.prototype.trim) {
    String.prototype.trim = function () {
        return this.replace(/^\s+|\s+$/g, '');
    }
}


var Uri = function (str) {
    var uri = "",
        o = {    strictMode: false,
            key: ["source", "protocol", "authority", "userInfo", "user", "password", "host", "port", "relative", "path", "directory", "file", "query", "anchor"],
            q: {
                name: "queryKey",
                parser: /(?:^|&)([^&=]*)=?([^&]*)/g
            },
            parser: {
                strict: /^(?:([^:\/?#]+):)?(?:\/\/((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?))?((((?:[^?#\/]*\/)*)([^?#]*))(?:\?([^#]*))?(?:#(.*))?)/,
                loose: /^(?:(?![^:@]+:[^:@\/]*@)([^:\/?#.]+):)?(?:\/\/)?((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?)(((\/(?:[^?#](?![^?#\/]*\.[^?#\/.]+(?:[?#]|$)))*\/?)?([^?#\/]*))(?:\?([^#]*))?(?:#(.*))?)/
            }},
        m = o.parser[o.strictMode ? "strict" : "loose"].exec(str),
        uri = {},
        i = 14;

    while (i--) uri[o.key[i]] = m[i] || "";

    uri[o.q.name] = {};
    uri[o.key[12]].replace(o.q.parser, function ($0, $1, $2) {
        if ($1) uri[o.q.name][$1] = $2;
    });


    Uri.prototype.protocol = function () {
        return (uri["protocol"] || "").trim();
    };
    Uri.prototype.path = function () {
        return (uri["path"] || "").trim();
    };
    Uri.prototype.host = function () {
        return (uri["host"] || "").trim();
    };
    Uri.prototype.valid = function () {
        return uri["protocol"] != "" && uri["host"] != "" && uri["path"] != "";
    };
}

Sahi.prototype.links = function () {
    //trace = window.open().document;
    try {
        return JSON.stringify(links_in_window(window));
    }
    catch (e) {
        //trace.write("links" + e.message + "<br>");
        return e ;
    }
};

Sahi.prototype.current_url = function () {
    return window.location;
}

Sahi.prototype.referrer = function () {
    return window.document.referrer;
}


Sahi.prototype.open_start_page_ch = function (url, window_parameters) {
    window.open(url, "_self", window_parameters);
    //window.open(url, "defaultSahiPopup", window_parameters);
    //window.close();
}

Sahi.prototype.open_start_page_ie = function (url, window_parameters) {
    window.open(url, "_self", window_parameters);
}

Sahi.prototype.open_start_page_ff = function (url, window_parameters) {
    window.open(url, "_self", window_parameters);
}

Sahi.prototype.info = function () {
    return "title = " + window.document.title + " referrer = " + window.document.referrer + " history = " + window.history.entries;
}

function links_in_window(w) {
   //trace.write("links_in_window debut<br>")
    try {
        var res = new Array(),
            arr_lnks = null;
        if (w !== undefined) {
            if (w.document !== undefined) {
                arr_lnks = links_in_document(w.document);
                for (var i = 0; i < arr_lnks.length; i++) {
                    if (is_selectable(arr_lnks[i], w.location)) {
                        res.push({href: arr_lnks[i].href, target: arr_lnks[i].target, text: arr_lnks[i].textContent});
                    }
                }
                for (var j = 0; j < w.frames.length; j++) {
                    res = res.concat(this.links_in_window(w.frames[j]));
                }
            }
        }
    }
    catch (e) {
        //trace.write("links_in_window" + e.message + "<br>");
    }
    //trace.write("links_in_window fin<br>")
    return res;
}
function links_in_document(d) {
    try {
       return d.links;
    }
    catch (e) {
        //trace.write("links_in_document" + e.message + "<br>");
      return new Array();
    }
}
function is_selectable(link, url_window) {
    var href = link.href,
        uri = new Uri(href),
        protocol = uri.protocol(),
        path = uri.path(),
        length = ".svg".length;

    return  (protocol == "http" || protocol == "https") &&
        href != url_window &&
        uri.valid() == true &&
        link.textContent != "" &&
        (link.target == "_top" || link.target == "_parent" || link.target == "_self" || link.target == "") &&  //on exclue _blank et id car cela cree une nouvelle fenetre
        [".svg", ".gif", ".jpeg", ".jpg", ".png", ".pdf"].indexOf(path.substr(path.length - length - 1, length)) < 0
}