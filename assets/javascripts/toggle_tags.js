// IE compatibility
if (!Array.prototype.indexOf) {
    Array.prototype.indexOf = function (searchElement /*, fromIndex */ ) {
        "use strict"
        if (this == null) {
            throw new TypeError()
        }
        var t = Object(this)
        var len = t.length >>> 0
        if (len === 0) {
            return -1
        }
        var n = 0
        if (arguments.length > 1) {
            n = Number(arguments[1]);
            if (n != n) { // shortcut for verifying if it's NaN
                n = 0
            } else if (n != 0 && n != Infinity && n != -Infinity) {
                n = (n > 0 || -1) * Math.floor(Math.abs(n));
            }
        }
        if (n >= len) {
            return -1
        }
        var k = n >= 0 ? n : Math.max(len - Math.abs(n), 0);
        for (; k < len; k++) {
            if (k in t && t[k] === searchElement) {
                return k
            }
        }
        return -1
    }
}

(function ($) {
  $.fn.toggleCloudViaFor = function(cloud_trigger, tag_container) {
    var tag_cloud = $(this)

    cloud_trigger.click(function(e) {
      tag_cloud.toggle()
      e.preventDefault()
    })

    var tag_items = tag_cloud.children()

    $(tag_items).click(function(e) {
      var tag_value = $(this).attr("data-tag")
      $(this).toggleTagFor(tag_value, tag_container)

      show_selected_tags_from(tag_container, tag_cloud)

      e.preventDefault()
    })

    tag_cloud.toggle(false)
    show_selected_tags_from(tag_container, tag_cloud)

    tag_container.keyup(function(e) {
      show_selected_tags_from(tag_container, tag_cloud)
    })

    tag_container.change(function(e) {
      show_selected_tags_from(tag_container, tag_cloud)
    })
  }

  function show_selected_tags_from(tag_container, tag_cloud) {
    var current_tags = tags_to_array(tag_container.attr("value"))
    update_selected_tags(current_tags, tag_cloud)
  }

  function update_selected_tags(selected_tags, tag_cloud) {
    tag_cloud.children().each(function(index, tag_child) {
      var tag_value = $(tag_child).attr("data-tag")
      if(selected_tags.indexOf(tag_value.toLowerCase()) == -1)
        $(tag_child).removeClass("selected")
      else {
        $(tag_child).addClass("selected")
      }
    })
  }

  $.fn.toggleTagFor = function(tag_name, tag_container) {
    var content_tags = tags_to_array(tag_container.attr("value")) 
    var this_tag_index = content_tags.indexOf(tag_name.toLowerCase())

    if(this_tag_index == -1) {
      content_tags.push(tag_name)
    } else {
      content_tags.splice(this_tag_index, 1)
    }

    tag_container.attr("value", content_tags.join(" "))
  }

  function tags_to_array(tags) {
    if (!tags) tags = '';
    dirty_items = tags.split(/[,#\s]+/)

    dirty_items = $.map(dirty_items, function(val, i){
      return val.toLowerCase()
    })

    return $.grep(dirty_items, function(val, i){
      return (val.length > 0)
    })
  }
})(jQuery)
