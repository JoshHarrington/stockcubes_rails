function clearNotice(){
  $(".alert-notice").animate({opacity:'0'}, 1500);
};

$(document).on('turbolinks:load', function(){
	setTimeout(function() {clearNotice();}, 5000);
});