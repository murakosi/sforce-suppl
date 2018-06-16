
(function ($) {

    var jqXHR = null;

    $.extend({

        ajaxOptions: function (options) {
            return $.extend({
                action: null,
                method: "GET",
                data: null,
                datatype: "",
                contentType: "application/json",
                parseJSON: false
            }, options);
        },

        getAjaxOptions: function (action, method, data, datatype, contentType = "application/json") {
            return $.ajaxOptions({
                action: action,
                method: method,
                data: data,
                datatype: datatype,
                contentType: contentType,
            });
        },

        ajaxCallbacks: function (options) {
            return $.extend({
                doneCallback: function () { },
                doneCallbackParams: null,
                failCallback: function () { },
                failCallbackParams: null,
                alwaysCallback: function () { },
                alwaysCallbackParams: null
            }, options);
        },

        getAjaxCallbacks: function (doneCallback, failCallback, alwaysCallback, doneCallbackParams) {
            return $.ajaxCallbacks({
                doneCallback: doneCallback,
                doneCallbackParams: doneCallbackParams,
                failCallback: failCallback,
                alwaysCallback: alwaysCallback,
            });
        },

        executeAjax: function (options, callbacks) {

            if (jqXHR) {
                return;
            }

            jqXHR = $.ajax({
                url: options.action,
                type: options.method,
                dataType: options.datatype,
                contentType: options.contentType,
                data: JSON.stringify(options.data),
                cache: false
            });

            jqXHR.done(function (data, stat, xhr) {
                jqXHR = null;
                console.log({ done: stat, data: data, xhr: xhr });
                return callbacks.doneCallback($.parseJSON(xhr.responseText), callbacks.doneCallbackParams);
            });

            jqXHR.fail(function (xhr, stat, err) {
                jqXHR = null;
                console.log({ fail: stat, error: err, xhr: xhr });
                return callbacks.failCallback($.parseJSON(xhr.responseText), callbacks.failCallbackParams);
            });

            jqXHR.always(function (res1, stat, res2) {
                jqXHR = null;
                console.log({ always: stat, res1: res1, res2: res2 });
                return callbacks.alwaysCallback(callbacks.alwaysCallbackParams)
            });
        }
    });
})(jQuery, this);

