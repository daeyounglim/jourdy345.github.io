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
        e.preventDefault();
        e.stopPropagation();
        return false;
      }
    }
  });
  $('.playlist-button button').on('click', function(e) {
    var $this;
    $this = $(this);
    if ($this.hasClass('button-active')) {
      return $this.removeClass('button-active');
    } else {
      $this.addClass('button-active');
      return $this.siblings().removeClass('button-active');
    }
  });
  onPlayerReady = function(event) {
    event.target.playVideo();
  };
  onPlayerStateChange = function(event) {
    var currentVideoIndex, i;
    if (event.data === YT.PlayerState.ENDED) {
      if ($('.playlist-button .repeat-all').hasClass('button-active')) {
        if (window.Player.getVideoData().video_id === window.Playlist.get()[window.Playlist.get().length - 1].id) {
          console.log('from repeat-all');
          return window.Playlist.play({
            videoId: window.Playlist.get()[0].id,
            suggestedQuality: 'large'
          });
        } else {
          currentVideoIndex = _.findIndex(window.Playlist.get(), function(chr) {
            return chr.id === window.Player.getVideoData().video_id;
          });
          console.log('>>', currentVideoIndex);
          return window.Playlist.play({
            videoId: window.Playlist.get()[currentVideoIndex + 1].id,
            suggestedQuality: 'large'
          });
        }
      } else if ($('.playlist-button .repeat-one').hasClass('button-active')) {
        console.log('from repeat-one');
        return window.Playlist.play({
          videoId: window.Player.getVideoData().video_id,
          suggestedQuality: 'large'
        });
      } else if ($('.playlist-button .shuffle').hasClass('button-active')) {
        console.log('from shuffle');
        currentVideoIndex = _.findIndex(window.ShuffledPlaylist, function(chr) {
          return chr.id === window.Player.getVideoData().video_id;
        });
        delete window.ShuffledPlaylist[currentVideoIndex];
        window.ShuffledPlaylist = _.compact(window.ShuffledPlaylist);
        if (window.ShuffledPlaylist.length) {
          return window.Playlist.play({
            videoId: window.ShuffledPlaylist[0].id,
            suggestedQuality: 'large'
          });
        } else {
          window.ShuffledPlaylist = _.shuffle(window.Playlist.get());
          i = Math.floor(Math.random() * window.Playlist.get().length);
          return window.Playlist.play({
            videoId: window.Playlist.get()[i].id,
            suggestedQuality: 'large'
          });
        }
      } else {
        console.log('from no nothing');
        currentVideoIndex = _.findIndex(window.Playlist.get(), function(chr) {
          return chr.id === window.Player.getVideoData().video_id;
        });
        console.log('>>', currentVideoIndex);
        return window.Playlist.play({
          videoId: window.Playlist.get()[currentVideoIndex + 1].id,
          suggestedQuality: 'large'
        });
      }
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
      videoId: '',
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
      var each, j, len, ref, templist;
      ref = this.list;
      for (j = 0, len = ref.length; j < len; j++) {
        each = ref[j];
        templist = JSON.stringify(this.list, null, '  ');
        if (templist.match(item.id)) {
          console.log('from check !!' + item.id);
          return true;
        }
        return false;
      }
    };

    Playlist.prototype.render = function() {
      var $playtemplate, item, j, len, ref;
      $playtemplate = $('.play-template');
      $('#playlist .item').remove();
      ref = this.list;
      for (j = 0, len = ref.length; j < len; j++) {
        item = ref[j];
        $playtemplate = $('#playlist .play-template').clone();
        $playtemplate.find('.playlist-title').html(item.title);
        $playtemplate.find('.playlist-date').html(item.date.slice(0, 10));
        $playtemplate.data('video-id', item.id);
        $playtemplate.attr('data-video-id', item.id);
        $playtemplate.on('dblclick', function(e) {
          var $this, $video_id;
          $this = $(this);
          $video_id = $this.data('video-id');
          console.log('from double click ' + $video_id);
          return window.Playlist.play({
            videoId: $video_id,
            suggestedQuality: 'large'
          });
        });
        $playtemplate.removeClass('play-template');
        $playtemplate.removeClass('hide');
        $playtemplate.addClass('item');
        $('#playlist tbody').append($playtemplate);
        console.log('from render ' + this.list);
        console.log($playtemplate.data('video-id'));
        true;
      }
      $('#playlist .item').on('click', function(e) {
        var $this;
        $this = $(this);
        $this.addClass('active');
        return $this.siblings().removeClass('active');
      });
      return window.ShuffledPlaylist = _.shuffle(window.Playlist.get());
    };

    Playlist.prototype.play = function(item) {
      console.log('>1 ', item);
      $('#playlist .bar-container').addClass('hide');
      $("#playlist tr[data-video-id=" + item.videoId + "]").find('.bar-container').removeClass('hide');
      window.Player.loadVideoById(item);
      return true;
    };

    Playlist.prototype.removeById = function(id) {
      var index;
      index = _.findIndex(this.list, function(chr) {
        return chr.id = id;
      });
      delete this.list[index];
      this.list = _.compact(this.list);
      return window.Playlist.render();
    };

    Playlist.prototype.shuffle = function() {
      return true;
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
        var data, item, j, len, ref;
        data = [];
        ref = response.items;
        for (j = 0, len = ref.length; j < len; j++) {
          item = ref[j];
          data.push({
            title: item.snippet.title,
            id: item.id.videoId,
            imgUrl: item.snippet.thumbnails["default"].url,
            date: item.snippet.publishedAt
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
    console.log(suggestion);
    window.Playlist.add(suggestion);
    return window.Playlist.render();
  });
});
