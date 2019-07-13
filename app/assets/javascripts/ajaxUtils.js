
(function ($) {

    var jqXHR = null;

    $.extend({

        ajaxOptions: function (options) {
            return $.extend({
                action: null,
                method: null,
                data: null,
                datatype: "",
                processData: true,
                contentType: null,
                showProgress: true
                //parseJSON: false
            }, options);
        },

        getAjaxOptions: function (action, method, data, datatype, contentType, showProgress = true) {
            var ajaxContentType = contentType;
            var ajaxProcessData = true;
            var ajaxData = data;

            if (contentType == null || contentType == undefined) {
                ajaxContentType = "application/json";
                ajaxData = JSON.stringify(data);
            }

            return $.ajaxOptions({
                action: action,
                method: method,
                data: ajaxData,
                datatype: datatype,
                processData: ajaxProcessData,
                contentType: ajaxContentType,
                showProgress: showProgress
            });
        },

        ajaxCallbacks: function (options) {
            return $.extend({
                doneCallback: function (json, params) { },
                doneCallbackParams: null,
                failCallback: function (json, params) { },
                failCallbackParams: null,
                alwaysCallback: function (params) { },
                alwaysCallbackParams: null
            }, options);
        },

        getAjaxCallbacks: function (doneCallback, failCallback, callbackParams) {
            return $.ajaxCallbacks({
                doneCallback: doneCallback,
                doneCallbackParams: callbackParams,
                failCallback: failCallback,
                failCallbackParams: callbackParams
            });
        },

        isAjaxBusy: function () {
            if (jqXHR) {
                return true;
            } else {
                return false;
            }
        },

        abortAjax: function () {
            if (jqXHR) {
                jqXHR.abort();
            }
        },



        executeAjax: function (options, callbacks, raw = false) {
            function showProgress() {
                $("#progress-line").addClass("progress-line");
                $("#progress").css("visibility","visible");
            };

            function hideProgress() {
                $("#progress-line").removeClass("progress-line");
                $("#progress").css("visibility","hidden");            
            };

            if (jqXHR) {
                return;
            }

            if(options.showProgress){
                showProgress();
            }

            jqXHR = $.ajax({
                url: options.action,
                type: options.method,
                dataType: options.datatype,
                processData: options.processData,
                contentType: options.contentType,
                data: options.data,
                cache: false
            });

            jqXHR.done(function (data, stat, xhr) {
                jqXHR = null;
                console.log({ done: stat, data: data, xhr: xhr });
                if (raw){
                    return callbacks.doneCallback(xhr.responseText, callbacks.doneCallbackParams);
                }else{
                    return callbacks.doneCallback($.parseJSON(xhr.responseText), callbacks.doneCallbackParams);
                }
            });

            jqXHR.fail(function (xhr, stat, err) {
                jqXHR = null;
                console.log({ fail: stat, error: err, xhr: xhr });
                if (raw){
                    return callbacks.failCallback(xhr.responseText, callbacks.failCallbackParams);
                }else{
                    return callbacks.failCallback($.parseJSON(xhr.responseText), callbacks.failCallbackParams);
                }
            });

            jqXHR.always(function (res1, stat, res2) {
                jqXHR = null;
                console.log({ always: stat, res1: res1, res2: res2 });
                if(options.showProgress){
                    hideProgress();
                }
                return callbacks.alwaysCallback(callbacks.alwaysCallbackParams);
            });
        }

    });
})(jQuery, this);

