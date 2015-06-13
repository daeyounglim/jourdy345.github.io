jQuery(function() {
  var Playlist, Results, done, onPlayerReady, onPlayerStateChange, stopVideo;
  window.Player = void 0;
  done = false;
  $(document).on('keydown', function(e) {
    var $active, $this;
    $active = $('#playlist .item.active');
    if ($active.length) {
      if (e.keyCode === 8) {
        $('.forBackspace').focus();
        $this = $active.first();
        window.Playlist.removeById($this.data('video-id'));
        window.Playlist.render();
        e.preventDefault();
        e.stopPropagation();
        return false;
      }
    }
  });
  onPlayerReady = function(event) {
    event.target.playVideo();
  };
  onPlayerStateChange = function(event) {
    var currentVideoIndex;
    if (event.data === YT.PlayerState.ENDED) {
      console.log('the video ended');
      currentVideoIndex = _.findIndex(window.Playlist.get(), function(chr) {
        return chr.id === window.Player.getVideoData().video_id;
      });
      console.log('>>', currentVideoIndex);
      return window.Player.loadVideoById({
        videoId: window.Playlist.get()[currentVideoIndex + 1].id,
        suggestedQuality: 'large'
      });
    }
  };
  stopVideo = function() {
    window.Player.stopVideo();
  };
  window.onYouTubeIframeAPIReady = function() {
    console.log('CALL');
    window.Player = new YT.Player('player', {
      height: '631.8',
      width: '1036.8',
      videoId: 'M7lc1UVf-VE',
      playerVars: {
        'autoplay': 1,
        'controls': 2
      },
      events: {
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
      var $playtemplate, i, item, len, ref;
      $playtemplate = $('.play-template');
      $('#playlist .item').remove();
      ref = this.list;
      for (i = 0, len = ref.length; i < len; i++) {
        item = ref[i];
        $playtemplate = $('#playlist .play-template').clone();
        $playtemplate.find('.playlist-title').html(item.title);
        $playtemplate.find('.playlist-videoId').html(item.id);
        $playtemplate.data('video-id', item.id);
        $playtemplate.on('dblclick', function(e) {
          var $this, $video_id;
          $this = $(this);
          $video_id = item.id;
          return window.Player.loadVideoById($video_id, 'large');
        });
        $playtemplate.removeClass('play-template');
        $playtemplate.removeClass('hide');
        $playtemplate.addClass('item');
        $('#playlist tbody').append($playtemplate);
        console.log('from render ' + this.list);
        console.log($playtemplate.data('video-id'));
        true;
      }
      return $('#playlist .item').on('click', function(e) {
        var $this;
        $this = $(this);
        $this.addClass('active');
        return $this.siblings().removeClass('active');
      });
    };

    Playlist.prototype.play = function(item) {
      window.Player.loadVideoById({
        id: item.id,
        suggestedQuality: 'large'
      });
      return true;
    };

    Playlist.prototype.removeById = function(id) {
      var index;
      index = _.findIndex(this.list, function(chr) {
        return chr.id = id;
      });
      delete this.list[index];
      _.compact(this.list);
      return window.Playlist.render();
    };

    return Playlist;

  })();
  window.Playlist = new Playlist();
  Results = new Bloodhound({
    datumTokenizer: function(d) {
      return Bloodhound.tokenizers.whitespace(d.title);
    },
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    limit: 50,
    remote: {
      url: "https://www.googleapis.com/youtube/v3/search?q=__QUERY__&part=snippet&maxResults=50&type=video&key=AIzaSyCImmWz0DcJdeD45YTwGB_ZmhNv167bwpM",
      wildcard: '__QUERY__',
      filter: function(response) {
        var data, i, item, len, ref;
        data = [];
        ref = response.items;
        for (i = 0, len = ref.length; i < len; i++) {
          item = ref[i];
          data.push({
            title: item.snippet.title,
            id: item.id.videoId,
            imgUrl: item.snippet.thumbnails["default"].url
          });
        }
        return data;
      }
    }
  });
  Results.initialize();
  return $('#bloodhound .typeahead').typeahead({
    limit: 5,
    minLength: 1,
    highlight: true
  }, {
    name: 'searchYoutube',
    minLength: 1,
    highlight: true,
    valueKey: 'name',
    source: Results.ttAdapter(),
    templates: {
      suggestion: Handlebars.compile('<img src="{{imgUrl}}" /><p><strong>{{title}} | {{id}}<strong></p>')
    }
  }).on('typeahead:selected', function(e, suggestion, name) {
    window.Playlist.add(suggestion);
    return window.Playlist.render();
  });
});
