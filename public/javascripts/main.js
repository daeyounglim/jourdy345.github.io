jQuery(function() {
  var Playlist;
  Playlist = (function() {
    function Playlist(list) {
      this.list = list;
      if (!this.list) {
        this.list = [];
      }
    }

    Playlist.prototype.get = function() {
      return this.list;
    };

    Playlist.prototype.add = function(item) {
      this.list.push(item);
      return this.render();
    };

    Playlist.prototype.add_to_next = function(item) {
      return this.list.unshift(item);
    };

    Playlist.prototype.render = function() {
      var $playtemplate, i, item, len, ref;
      ref = this.list;
      for (i = 0, len = ref.length; i < len; i++) {
        item = ref[i];
        $playtemplate = $('.play-template').clone();
        $playtemplate.find('.title').html(item.title);
        $playtemplate.removeClass('play-template');
        $playtemplate.removeClass('hide');
        $('#playlist ul.playlist').append($playtemplate);
      }
      console.log(this.list);
      return true;
    };

    Playlist.prototype.play = function() {
      return true;
    };

    return Playlist;

  })();
  window.Playlist = new Playlist();
  return $('[data-toggle~=youtube-search]').on('submit', function() {
    var $query;
    $query = $('#query');
    $.ajax({
      url: "https://www.googleapis.com/youtube/v3/search",
      type: "get",
      data: {
        q: $query.val(),
        part: 'snippet',
        key: 'AIzaSyCImmWz0DcJdeD45YTwGB_ZmhNv167bwpM'
      },
      success: function(d, s, x) {
        var $template, $ul, i, item, len, ref;
        $ul = $('#search-container ul.collection');
        ref = d.items;
        for (i = 0, len = ref.length; i < len; i++) {
          item = ref[i];
          $template = $('.item-template').clone();
          console.log(item.id.videoId, item.snippet.title, item.snippet.thumbnails["default"].url);
          $template.find('img').attr('src', item.snippet.thumbnails["default"].url);
          $template.find('span.title').html(item.snippet.title || 'Untitled');
          $template.find('p').html(item.snippet.description.slice(0, 11) + '...');
          $template.data('video-id', item.id.videoId);
          $template.data('video-title', item.snippet.title || 'Untitled');
          $template.on('click', function(e) {
            var $this;
            $this = $(this);
            console.log('Clicked ! ' + $this.data('video-id'));
            return window.Playlist.add({
              id: $this.data('video-id'),
              title: $this.data('video-title')
            });
          });
          $template.removeClass('hide');
          $template.removeClass('item-template');
          $ul.append($template);
        }
        return true;
      },
      error: function(x, s, d) {
        return alert('Error:' + s);
      }
    });
    return false;
  });
});
