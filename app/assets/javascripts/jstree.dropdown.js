(function ($, undefined) {
    "use strict";

    $.jstree.defaults.dropdown = $.noop;
    $.jstree.plugins.dropdown = function (options, parent) {

        this.edit = function (obj, default_text, callback) {
            var node = this.get_node(obj);

            if(!node.li_attr.editable || !node.li_attr.is_picklist){
                return parent.edit.call(this, obj, default_text, callback);
            }
 
            var rtl, w, a, s, t, h1, h2, fn, tmp, cancel = false;
            obj = this.get_node(obj);
            if(!obj) { return false; }
            if(!this.check("edit", obj, this.get_parent(obj))) {
                this.settings.core.error.call(this, this._data.core.last_error);
                return false;
            }
            tmp = obj;
            default_text = typeof default_text === 'string' ? default_text : obj.text;
            this.set_text(obj, "");
            obj = this._open_to(obj);
            tmp.text = default_text;

            rtl = this._data.core.rtl;
            w  = this.element.width();
            this._data.core.focused = tmp.id;
            a  = obj.children('.jstree-anchor').focus();
            s  = $('<span>');
            
            t  = default_text;
            h1 = $("<"+"div />", { css : { "position" : "absolute", "top" : "-200px", "left" : (rtl ? "0px" : "-1000px"), "visibility" : "hidden" } }).appendTo("body");
            h2 = $("<"+"select />", {
                        "value" : "select these text",
                        "class" : "jstree-rename-input",
                        // "size" : t.length,
                        "css" : {
                            "padding" : "0",
                            "border" : "1px solid silver",
                            "box-sizing" : "border-box",
                            "display" : "inline-block",
                            "height" : (this._data.core.li_height) + "px",
                            "lineHeight" : (this._data.core.li_height) + "px",
                            "width" : "150px" // will be set a bit further down
                        },
                        "blur" : $.proxy(function (e) {
                            e.stopImmediatePropagation();
                            e.preventDefault();
                            var i = s.children(".jstree-rename-input"),
                                v = i.val(),
                                f = this.settings.core.force_text,
                                nv;
                            if(v === "") { v = t; }
                            h1.remove();
                            s.replaceWith(a);
                            s.remove();
                            t = f ? t : $('<div></div>').append($.parseHTML(t)).html();
                            this.set_text(obj, t);
                            nv = !!this.rename_node(obj, f ? $('<div></div>').text(v).text() : $('<div></div>').append($.parseHTML(v)).html());
                            if(!nv) {
                                this.set_text(obj, t); // move this up? and fix #483
                            }
                            this._data.core.focused = tmp.id;
                            setTimeout($.proxy(function () {
                                var node = this.get_node(tmp.id, true);
                                if(node.length) {
                                    this._data.core.focused = tmp.id;
                                    node.children('.jstree-anchor').focus();
                                }
                            }, this), 0);
                            if(callback) {
                                callback.call(this, tmp, nv, cancel);
                            }
                            h2 = null;
                        }, this),
                        "keydown" : function (e) {
                            var key = e.which;
                            if(key === 27) {
                                cancel = true;
                                this.value = t;
                            }
                            if(key === 27 || key === 13 || key === 37 || key === 38 || key === 39 || key === 40 || key === 32) {
                                e.stopImmediatePropagation();
                            }
                            if(key === 27 || key === 13) {
                                e.preventDefault();
                                this.blur();
                            }
                        },
                        "click" : function (e) { e.stopImmediatePropagation(); },
                        "mousedown" : function (e) { e.stopImmediatePropagation(); },
                        "keyup" : function (e) {
                            h2.width(Math.min(h1.text("pW" + this.value).width(),w));
                        },
                        "keypress" : function(e) {
                            if(e.which === 13) { return false; }
                        }
                    });
                fn = {
                        fontFamily      : a.css('fontFamily')       || '',
                        fontSize        : a.css('fontSize')         || '',
                        fontWeight      : a.css('fontWeight')       || '',
                        fontStyle       : a.css('fontStyle')        || '',
                        fontStretch     : a.css('fontStretch')      || '',
                        fontVariant     : a.css('fontVariant')      || '',
                        letterSpacing   : a.css('letterSpacing')    || '',
                        wordSpacing     : a.css('wordSpacing')      || ''
                };
            s.attr('class', a.attr('class')).append(a.contents().clone()).append(h2);
            a.replaceWith(s);
            h1.css(fn);

            jQuery.each(node.li_attr.picklist_source, function(){
                $('<option/>', {
                    'value': this,
                    'text': this
                }).appendTo(h2);
            });

            h2.val(t);

            var longest = node.li_attr.picklist_source.reduce(function (a, b) { return a.length > b.length ? a : b; });
            h2.css(fn).width(Math.min(h1.text("pWW" + longest).width(),w)).select();
            
            $(document).one('mousedown.jstree touchstart.jstree dnd_start.vakata', function (e) {
                if (h2 && e.target !== h2) {
                    $(h2).blur();
                }
            });
        };
    }
})(jQuery);