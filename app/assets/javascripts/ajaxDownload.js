
(function ($) {
    // i'll just put them here to get evaluated on script load

    var task = null;

    $.extend({
        ajaxDownload: function (options) {

            if (task) {
                return false;
            }

            var settings = $.extend({
                url: null,
                method: "GET",
                data: null,
                successCallback: function (url) { },
                failCallback: function (response, url, error) { },
                alwaysCallback: function () { }
            }, options);

            task = $.fileDownload(settings.url, {
                httpMethod: settings.method,
                data: settings.data
            })

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
            })
        }
    });

})(jQuery, this);
