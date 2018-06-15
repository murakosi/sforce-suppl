
(function ($) {
 
    var jqXHR = null;
    var settings = null;

    $.extend({

        ajaxOptions: function (options) {
            mergedOptions = $.extend({
              "action": "",
              "method": "GET",
              "data": "",
              "datatype": "",
              "parseJSON": false,
            }, options);
        }

        ajaxCallbacks: function (doneCallback, failCallback, alwaysCallback) {
            callbacks = $.extend({
                doneCallback: doneCallback,
                failCallback: failCallback,
                alwaysCallback: alwaysCallback,
            }, 
        }

        ajaxCallbackParams: function (doneParams, failParams, alwaysParams = null) {
            {
                doneParams: params
            }

        }

        executeAjax: function (options, callbacks, callbackParams = null) {

            if (jqXHR) {
              return;
            }

            jqXHR = $.ajax({
              url: options.action,
              type: options.method,
              data: options.data,
              dataType: options.datatype,
              cache: false
            });

            jqXHR.done( function (data, stat, xhr) {
              jqXHR = null;
              console.log( {done: stat, data: data, xhr: xhr} );
              if params.
              return callbacks.doneCallback($.parseJSON(xhr.responseText), params);
            });

            jqXHR.fail( function (xhr, stat, err) {
              jqXHR = null;
              console.log( {fail: stat, error: err, xhr: xhr} );
              return callbacks.failCallback($.parseJSON(xhr.responseText), params);
            });

            jqXHR.always( function (res1, stat, res2) {
              jqXHR = null;
              console.log( {always: stat, res1: res1, res2: res2} );
              return callbacks.alwaysCallback()
            });
        }
   });
})(jQuery, this);            

