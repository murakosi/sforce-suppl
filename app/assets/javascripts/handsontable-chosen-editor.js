/// chosen plugin
(function (Handsontable) {
    "use strict";

    var ChosenEditor = Handsontable.editors.TextEditor.prototype.extend();

    ChosenEditor.prototype.prepare = function (row, col, prop, td, originalValue, cellProperties) {

        Handsontable.editors.TextEditor.prototype.prepare.apply(this, arguments);

        this.options = {};

        if (this.cellProperties.chosenOptions) {
            this.options = $.extend(this.options, cellProperties.chosenOptions);
        }

        cellProperties.chosenOptions = $.extend({}, cellProperties.chosenOptions);
    };

    ChosenEditor.prototype.createElements = function () {
        this.$body = $(document.body);

        // change "select" to "TEXTAREA"
        //this.TEXTAREA = document.createElement('select');
        this.TEXTAREA = document.createElement('TEXTAREA');
        this.$textarea = $(this.TEXTAREA);

        Handsontable.dom.addClass(this.TEXTAREA, 'handsontableInput');

        this.textareaStyle = this.TEXTAREA.style;
        this.textareaStyle.width = 0;
        this.textareaStyle.height = 0;

        this.TEXTAREA_PARENT = document.createElement('DIV');
        Handsontable.dom.addClass(this.TEXTAREA_PARENT, 'handsontableInputHolder');

        this.textareaParentStyle = this.TEXTAREA_PARENT.style;
        this.textareaParentStyle.top = 0;
        this.textareaParentStyle.left = 0;
        this.textareaParentStyle.display = 'none';
        this.textareaParentStyle.width = "200px";

        this.TEXTAREA_PARENT.appendChild(this.TEXTAREA);
        
        // add "select" for chosen editor
        this.select = document.createElement('SELECT');
        this.$select = $(this.select);
        this.TEXTAREA_PARENT.appendChild(this.select);

        this.instance.rootElement.appendChild(this.TEXTAREA_PARENT);

        var that = this;
        this.instance._registerTimeout(setTimeout(function () {
            that.refreshDimensions();
        }, 0));
    };

    var onChosenChanged = function () {
        if (!this.cellProperties.chosenOptions.multiple) {
            this.close();
            this.finishEditing();
        }
    };

    var onChosenClosed = function () {
        if (!this.cellProperties.chosenOptions.multiple) {
            this.close();
            this.finishEditing();
        }
    };

    var onBeforeKeyDown = function (event) {
        var instance = this;
        var that = instance.getActiveEditor();

        var keyCodes = Handsontable.helper.KEY_CODES;
        var ctrlDown = (event.ctrlKey || event.metaKey) && !event.altKey; //catch CTRL but not right ALT (which in some systems triggers ALT+CTRL)

        //Process only events that have been fired in the editor
        if (event.target.tagName !== "INPUT") {
            return;
        }
        if (event.keyCode === 17 || event.keyCode === 224 || event.keyCode === 91 || event.keyCode === 93) {
            //when CTRL or its equivalent is pressed and cell is edited, don't prepare selectable text in textarea
            event.stopImmediatePropagation();
            return;
        }

        var target = event.target;

        switch (event.keyCode) {
            case keyCodes.ARROW_RIGHT:
                if (Handsontable.dom.getCaretPosition(target) !== target.value.length) {
                    event.stopImmediatePropagation();
                } else {
                    that.$select.trigger("chosen:close");
                }
                break;

            case keyCodes.ARROW_LEFT:
                if (Handsontable.dom.getCaretPosition(target) !== 0) {
                    event.stopImmediatePropagation();
                } else {
                    that.$select.trigger("chosen:close");
                }
                break;

            case keyCodes.ENTER:
                if (that.cellProperties.chosenOptions.multiple) {
                    event.stopImmediatePropagation();
                    event.preventDefault();
                    event.stopPropagation();
                }

                break;

            case keyCodes.A:
            case keyCodes.X:
            case keyCodes.C:
            case keyCodes.V:
                if (ctrlDown) {
                    event.stopImmediatePropagation(); //CTRL+A, CTRL+C, CTRL+V, CTRL+X should only work locally when cell is edited (not in table context)
                }
                break;

            case keyCodes.BACKSPACE:
                var txt = $(that.TEXTAREA_PARENT).find("input").val();
                $(that.TEXTAREA_PARENT).find("input").val(txt.substr(0,txt.length-1)).trigger("keyup.chosen");

                event.stopImmediatePropagation();
                break;
            case keyCodes.DELETE:
            case keyCodes.HOME:
            case keyCodes.END:
                event.stopImmediatePropagation(); //backspace, delete, home, end should only work locally when cell is edited (not in table context)
                break;
        }

    };

    ChosenEditor.prototype.open = function (keyboardEvent) {
        this.refreshDimensions();
        this.textareaParentStyle.display = 'block';
        this.instance.addHook('beforeKeyDown', onBeforeKeyDown);

        this.$select.css({
            height: $(this.TD).height() + 4,
            'min-width': $(this.TD).outerWidth() - 4
        });

        //display the list
        this.$textarea.hide();

        //make sure that list positions matches cell position
        //this.$textarea.offset($(this.TD).offset());

        var options = $.extend({}, this.options, {
            width: "100%",
            search_contains: true
        });

        if (options.multiple) {
            this.$select.attr("multiple", true);
        } else {
            this.$select.attr("multiple", false);
        }

        this.$select.empty();
        this.$select.append("<option value=''></option>");
        var el = null;
        //var originalValue = (this.originalValue + "").split(",");
        // add splitter option
        var originalValue = $.map((this.originalValue + "").split(this.options.splitter), $.trim);
        if (options.data && options.data.length) {
            for (var i = 0; i < options.data.length; i++) {
                el = $("<option />");
                el.attr("value", options.data[i].id);
                el.html(options.data[i].label);

                if (originalValue.indexOf(options.data[i].id + "") > -1) {
                    el.attr("selected", true);
                }

                this.$select.append(el);
            }
        }

        if ($(this.TEXTAREA_PARENT).find(".chosen-container").length) {
            this.$select.chosen("destroy");
        }

        this.$select.chosen(options);

        var self = this;
        setTimeout(function () {

            self.$select.on('change', onChosenChanged.bind(self));
            self.$select.on('chosen:hiding_dropdown', onChosenClosed.bind(self));

            self.$select.trigger("chosen:open");

            $(self.TEXTAREA_PARENT).find("input").on("keydown", function(e) {
                if(e.keyCode === Handsontable.helper.KEY_CODES.ENTER /*|| e.keyCode === Handsontable.helper.KEY_CODES.BACKSPACE*/) {
                    if($(this).val()) {
                        e.preventDefault();
                        e.stopPropagation();
                    } else {
                        e.preventDefault();
                        e.stopPropagation();

                        self.close();
                        self.finishEditing();
                    }

                }

                if( e.keyCode === Handsontable.helper.KEY_CODES.BACKSPACE) {
                    var txt =  $(self.TEXTAREA_PARENT).find("input").val();

                    $(self.TEXTAREA_PARENT).find("input").val(txt.substr(0,txt.length-1)).trigger("keyup.chosen");

                    e.preventDefault();
                    e.stopPropagation();
                }

                if(e.keyCode === Handsontable.helper.KEY_CODES.ARROW_DOWN || e.keyCode === Handsontable.helper.KEY_CODES.ARROW_UP) {
                    e.preventDefault();
                    e.stopPropagation();
                }

            });

            setTimeout(function () {
                self.$select.trigger("chosen:activate").focus();

                if (keyboardEvent && keyboardEvent.keyCode && keyboardEvent.keyCode != 113) {
                    var key = keyboardEvent.keyCode;
                    var keyText = (String.fromCharCode((96 <= key && key <= 105) ? key - 48 : key)).toLowerCase();

                    $(self.TEXTAREA_PARENT).find("input").val(keyText).trigger("keyup.chosen");
                    self.$select.trigger("chosen:activate");
                }
            }, 1);
        }, 1);

    };

    ChosenEditor.prototype.init = function () {
        Handsontable.editors.TextEditor.prototype.init.apply(this, arguments);
    };

    ChosenEditor.prototype.close = function () {
        this.instance.listen();
        this.instance.removeHook('beforeKeyDown', onBeforeKeyDown);
        this.$select.off();
        this.$select.hide();
        // add to enable copy
        this.$textarea.show();
        Handsontable.editors.TextEditor.prototype.close.apply(this, arguments);
    };

    ChosenEditor.prototype.getValue = function() {
       if(!this.$select.val()) {
           return "";
       }
        if(typeof this.$select.val() === "object") {
            //return this.$select.val().join(",");
            // add splitter option
            return this.$select.val().join(this.options.splitter);
        }
        return this.$select.val();
    };

    ChosenEditor.prototype.focus = function () {
        this.instance.listen();
        // DO NOT CALL THE BASE TEXTEDITOR FOCUS METHOD HERE, IT CAN MAKE THIS EDITOR BEHAVE POORLY AND HAS NO PURPOSE WITHIN THE CONTEXT OF THIS EDITOR
        //Handsontable.editors.TextEditor.prototype.focus.apply(this, arguments);
    };  

    ChosenEditor.prototype.beginEditing = function (initialValue) {
        var onBeginEditing = this.instance.getSettings().onBeginEditing;
        if (onBeginEditing && onBeginEditing() === false) {
            return;
        }

        Handsontable.editors.TextEditor.prototype.beginEditing.apply(this, arguments);

    };

    ChosenEditor.prototype.finishEditing = function (isCancelled, ctrlDown) {
        this.instance.listen();
        return Handsontable.editors.TextEditor.prototype.finishEditing.apply(this, arguments);
    };

    Handsontable.editors.ChosenEditor = ChosenEditor;
    Handsontable.editors.registerEditor('chosen', ChosenEditor);

})(Handsontable);