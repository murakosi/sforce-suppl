
(function ($) {
 
    var task = null;
    var settings = null;

    $.extend({

        ajaxDownload: function (options) {

            if (task) {
                return false;
            }

            settings = $.extend({
                url: null,
                method: "POST",
                data: null,
                successCallback: function (url) { },
                failCallback: function (response, url, error) { },
                alwaysCallback: function () { }
            }, options);

            checkDownloadServiceAvailable();
           
            function checkDownloadServiceAvailable(){

                task = $.ajax({
                    url: "check",
                    type: "POST",
                    data: null,
                    dataType: "",
                    cache: false
                });

                task.done( function (data, stat, xhr) {
                    console.log("download ajax done");
                    return executeDownload();
                });

                task.fail( function (xhr, stat, err) {
                    task = null;
                    console.log("download ajax fail");
                });

                task.always ( function (res1, stat, res2) {
                    console.log("download ajax always");
                });
            }

            function executeDownload(){

                task = $.fileDownload(settings.url, {
                    httpMethod: settings.method,
                    data: settings.data
                });

                task.done(function (url) {
                    task = null;
                    return settings.successCallback(url);
                });

                task.fail(function (response, url, error) {
                    task = null;
                    return settings.failCallback(response, url, error);
                });

                task.always(function () {
                    task = null;
                    return settings.alwaysCallback();
                });
            }
        }
   });
})(jQuery, this);            

