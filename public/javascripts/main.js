jQuery(function() {
  var Playlist, done, onPlayerReady, onPlayerStateChange, player, stopVideo;
  player = void 0;
  done = false;
  onPlayerReady = function(event) {
    event.target.playVideo();
  };
  onPlayerStateChange = function(event) {
    if (event.data === YT.PlayerState.PLAYING && !done) {
      setTimeout(stopVideo, 1000);
      return done = true;
    } else if (event.data === YT.PlayerState.ENDED) {
      console.log('the video ended');
      player.loadVideoById({
        videoId: 'AnotherVideosID',
        suggestedQuality: 'large'
      });
      return player.playVideo();
    }
  };
  stopVideo = function() {
    player.stopVideo();
  };
  window.onYouTubeIframeAPIReady = function() {
    console.log('CALL');
    player = new YT.Player('player', {
      height: '631.8',
      width: '1036.8',
      videoId: 'M7lc1UVf-VE',
      events: {
        'onReady': onPlayerReady,
        'onStateChange': onPlayerStateChange
      }
    });
  };
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
      return this.list.push(item);
    };

    Playlist.prototype.add_to_next = function(item) {
      return this.list.unshift(item);
    };

    Playlist.prototype.check = function(item) {
      var each, i, len, ref, templist;
      ref = this.list;
      for (i = 0, len = ref.length; i < len; i++) {
        each = ref[i];
        templist = JSON.stringify(this.list, null, '  ');
        if (templist.match(item.id)) {
          console.log('from check !!' + item.id);
          return true;
        }
        return false;
      }
    };

    Playlist.prototype.remove = function(item) {};

    Playlist.prototype.render = function() {
      var $playtemplate, i, item, len, ref, results;
      $playtemplate = $('.play-template');
      $playtemplate.find('.title').html('');
      ref = this.list;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        item = ref[i];
        $playtemplate = $('.play-template').clone();
        $playtemplate.find('.title').html(item.title);
        $playtemplate.data('video-id', item.id);
        $playtemplate.removeClass('play-template');
        $playtemplate.removeClass('hide');
        $('#playlist ul.playlist').append($playtemplate);
        console.log('from render ' + this.list);
        results.push(true);
      }
      return results;
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
        maxResults: 50,
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
            var $this, video_list;
            $this = $(this);
            video_list = {
              id: $this.data('video-id'),
              title: $this.data('video-title')
            };
            console.log('Clicked ! ' + video_list);
            if (!window.Playlist.check(video_list)) {
              console.log('>>>>>');
              window.Playlist.add({
                id: $this.data('video-id'),
                title: $this.data('video-title')
              });
              return window.Playlist.render();
            }
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
