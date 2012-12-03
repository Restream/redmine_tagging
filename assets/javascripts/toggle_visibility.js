(function ($) {
  $.fn.toggleVisibilityVia = function (cloud_trigger) {

    var tag_cloud = $(this);

    cloud_trigger.click(function(e) {
      tag_cloud.toggle();
      e.preventDefault();
    })

    cloud_trigger.css("cursor", "pointer")
    cloud_trigger.css("border-bottom", "dashed 1px")
    cloud_trigger.css("text-decoration", "none")

    $(this).toggle();
  }
})(jQuery);
