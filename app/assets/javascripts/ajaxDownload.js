(function ($) {

    var task = null;
    var settings = null;

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

            if (task) {
                return false;
            }

            if(options.showProgress){
                showProgress();
            }

            checkDownloadServiceAvailable();

            function checkDownloadServiceAvailable() {

                task = $.ajax({
                    url: "check",
                    type: "POST",
                    data: null,
                    dataType: "",
                    cache: false
                });

                task.done(function (data, stat, xhr) {
                    console.log("Ajax download available");
                    return executeDownload();
                });

                task.fail(function (xhr, stat, err) {
                    task = null;
                    if(options.showProgress){
                        hideProgress();
                    }
                    console.log("Ajax download not available");
                });

                task.always(function (res1, stat, res2) {
                    console.log("download ajax always");
                });
            }

            function executeDownload() {
 
                task = $.fileDownload(options.url, {
                    httpMethod: options.method,
                    data: options.data
                });

                task.done(function (url) {
                    task = null;
                    return options.successCallback(url);
                });

                task.fail(function (response, url, error) {
                    task = null;
                    return options.failCallback(response, url, error);
                });

                task.always(function () {
                    task = null;
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

