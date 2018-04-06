/*
$(document).ready(function () {

    $(document).on('click', '#addButton', function () {

        var tabId = $('.tab li').length + 1;
        $('.tab').append('<li>Tab' + tabId + '</li>');

        $('.content').append('<li class="hide">' + 'new' + '</li>');


    });

    //クリックしたときのファンクションをまとめて指定
    //$('.tab li').on("click", function () {
    $(document).on('click', '.tab li', function () {

        //.index()を使いクリックされたタブが何番目かを調べ、
        //indexという変数に代入します。
        var index = $('.tab li').index(this);

        //コンテンツを一度すべて非表示にし、
        $('.content li').css('display', 'none');

        //クリックされたタブと同じ順番のコンテンツを表示します。
        $('.content li').eq(index).css('display', 'block');

        //一度タブについているクラスselectを消し、
        $('.tab li').removeClass('select');

        //クリックされたタブのみにクラスselectをつけます。
        $(this).addClass('select')
    });
});
*/
