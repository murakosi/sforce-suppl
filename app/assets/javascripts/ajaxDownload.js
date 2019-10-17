(function ($) {

    var _task = null;

    $.extend({

        ajaxDownloadOptions: function (options) {
            return $.extend({
                url: null,
                method: "POST",
                data: null,
                successCallback: function (url) { },
                failCallback: function (response, url, error) { },
                alwaysCallback: function () { }
            }, options);
        },

        getAjaxDownloadOptions: function (url, method, data, successCallback, failCallback, alwaysCallback, showProgress = true) {
            return $.ajaxDownloadOptions({
                url: url,
                method: method,
                data: data,
                successCallback: successCallback,
                failCallback: failCallback,
                alwaysCallback: alwaysCallback,
                showProgress: showProgress
            });
        },

        ajaxDownload: function (options) {

            if (_task) {
                return false;
            }

            if(options.showProgress){
                showProgress();
            }

            checkDownloadServiceAvailable();

            function checkDownloadServiceAvailable() {

                _task = $.ajax({
                    url: "check",
                    type: "POST",
                    data: null,
                    dataType: "",
                    cache: false
                });

                _task.done(function (data, stat, xhr) {
                    console.log("Ajax download available");
                    return executeDownload();
                });

                _task.fail(function (xhr, stat, err) {
                    _task = null;
                    if(options.showProgress){
                        hideProgress();
                    }
                    console.log("Ajax download not available");
                });

                _task.always(function (res1, stat, res2) {
                    console.log("download ajax always");
                });
            }

            function executeDownload() {
 
                _task = $.fileDownload(options.url, {
                    httpMethod: options.method,
                    data: options.data
                });

                _task.done(function (url) {
                    _task = null;
                    return options.successCallback(url);
                });

                _task.fail(function (response, url, error) {
                    _task = null;
                    return options.failCallback(response, url, error);
                });

                _task.always(function () {
                    _task = null;
                    if(options.showProgress){
                        hideProgress();
                    }
                    return options.alwaysCallback();
                });
            }

            function showProgress() {
                $("#progress-line").addClass("progress-line");
                $("#progress").css("visibility","visible");
            };

            function hideProgress() {
                $("#progress-line").removeClass("progress-line");
                $("#progress").css("visibility","hidden");            
            };
        }
    });
})(jQuery, this);

