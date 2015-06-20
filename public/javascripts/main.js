jQuery(function() {
  var Playlist, Results, done, onPlayerReady, onPlayerStateChange, stopVideo;
  window.Player = void 0;
  done = false;
  $(document).on('keydown', function(e) {
    var $active, $this, height, i, offset;
    $active = $('#playlist .item.active');
    $this = $active.first();
    if (e.shiftKey) {
      if (e.keyCode === 8) {
        if ($this.attr('data-video-id') === window.Player.getVideoData().video_id) {
          alert("Cannot delete currently running video.");
        } else {
          window.Playlist.remove($this.attr('id'));
          i = _.findIndex(window.Playlist.get(), function(chr) {
            return chr.id === window.Player.getVideoData().video_id;
          });
          offset = $('#' + i).find('td:first').offset();
          height = $('#' + i).height();
          $('.bar-container').css({
            'top': offset.top + 37 + height * 0.5,
            'left': offset.left - 10
          });
        }
      }
      return true;
    }
    return true;
  });
  $(function() {
    $('#sortable').sortable({
      stop: function(event, ui) {
        window.Playlist.remap();
      }
    });
    $('#sortable').disableSelection();
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
          return window.Playlist.play(0);
        } else {
          currentVideoIndex = _.findIndex(window.Playlist.get(), function(chr) {
            return chr.id === window.Player.getVideoData().video_id;
          });
          return window.Playlist.play(currentVideoIndex + 1);
        }
      } else if ($('.playlist-button .repeat-one').hasClass('button-active')) {
        currentVideoIndex = _.findIndex(window.Playlist.get(), function(chr) {
          return chr.id === window.Player.getVideoData().video_id;
        });
        return window.Playlist.play(currentVideoIndex);
      } else if ($('.playlist-button .shuffle').hasClass('button-active')) {
        currentVideoIndex = _.findIndex(window.ShuffledPlaylist, function(chr) {
          return chr.id === window.Player.getVideoData().video_id;
        });
        delete window.ShuffledPlaylist[currentVideoIndex];
        window.ShuffledPlaylist = _.compact(window.ShuffledPlaylist);
        if (window.ShuffledPlaylist.length) {
          i = _.findIndex(window.Playlist.get(), function(chr) {
            return chr.id === window.ShuffledPlaylist[0].id;
          });
          return window.Playlist.play(i);
        } else {
          window.ShuffledPlaylist = _.shuffle(window.Playlist.get());
          i = Math.floor(Math.random() * window.Playlist.get().length);
          return window.Playlist.play(i);
        }
      } else {
        currentVideoIndex = _.findIndex(window.Playlist.get(), function(chr) {
          return chr.id === window.Player.getVideoData().video_id;
        });
        return window.Playlist.play(currentVideoIndex + 1);
      }
    }
  };
  stopVideo = function() {
    window.Player.stopVideo();
  };
  window.onYouTubeIframeAPIReady = function() {
    window.Player = new YT.Player('player', {
      height: '631.8',
      width: '1036.8',
      videoId: '',
      playerVars: {
        'autoplay': 1,
        'controls': 1
      },
      events: {
        'onStateChange': onPlayerStateChange
      }
    });
  };
  Playlist = (function() {
    function Playlist(list) {
      this.list = list;
      this.list = JSON.parse(localStorage.videos || '[]');
      if (this.list.length) {
        this.render();
      }
    }

    Playlist.prototype.get = function() {
      return this.list;
    };

    Playlist.prototype.add = function(item) {
      this.list.push(item);
      return localStorage.videos = JSON.stringify(this.list);
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
          return true;
        }
        return false;
      }
    };

    Playlist.prototype.render = function() {
      var $playtemplate, index, item, j, len, ref;
      $playtemplate = $('.play-template');
      $('#playlist .item').remove();
      ref = this.list;
      for (j = 0, len = ref.length; j < len; j++) {
        item = ref[j];
        index = _.findIndex(this.list, function(chr) {
          return chr.id === item.id;
        });
        $playtemplate = $('#playlist .play-template').clone();
        $playtemplate.find('.playlist-title').html(item.title);
        $playtemplate.find('.playlist-date').html(item.date);
        $playtemplate.data('video-id', item.id);
        $playtemplate.attr('id', index);
        $playtemplate.attr('data-video-id', item.id);
        $playtemplate.removeClass('play-template');
        $playtemplate.removeClass('hide');
        $playtemplate.addClass('item');
        $('#playlist tbody').append($playtemplate);
      }
      $('#playlist .item').on('click', function(e) {
        var $this;
        $this = $(this);
        $this.addClass('active');
        return $this.siblings().removeClass('active');
      }).on('dblclick', function(e) {
        var $this, height, offset;
        $this = $(this);
        offset = $this.find('td:first').offset();
        height = $this.height();
        return window.Playlist.play($this.attr('id'));
      });
      return window.ShuffledPlaylist = _.shuffle(this.get());
    };

    Playlist.prototype.play = function(i) {
      var height, item, j, len, offset, ref;
      ref = this.list;
      for (j = 0, len = ref.length; j < len; j++) {
        item = ref[j];
        item.playing = 0;
      }
      this.list[i].playing = 1;
      offset = $("#" + i).find('td:first').offset();
      height = $("#" + i).height();
      $('.bar-container').css({
        'top': offset.top + 37 + height * 0.5,
        'left': offset.left - 10
      });
      return window.Player.loadVideoById(this.list[i].id, 0, 'large');
    };

    Playlist.prototype.remove = function(i) {
      delete this.list[i];
      this.list = _.compact(this.list);
      return window.Playlist.render();
    };

    Playlist.prototype.clear = function() {
      return this.list = [];
    };

    Playlist.prototype.remap = function() {
      var height, i, index, j, k, mapping, offset, ref, ref1, tempPlaylist;
      mapping = _.compact($("#sortable").sortable("toArray", {
        attribute: "id"
      }));
      tempPlaylist = [];
      for (i = j = 0, ref = this.list.length - 1; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
        tempPlaylist[i] = this.list[mapping[i]];
      }
      for (i = k = 0, ref1 = this.list.length - 1; 0 <= ref1 ? k <= ref1 : k >= ref1; i = 0 <= ref1 ? ++k : --k) {
        this.list[i] = tempPlaylist[i];
      }
      window.Playlist.render();
      index = _.findIndex(this.list, function(chr) {
        return chr.id === window.Player.getVideoData().video_id;
      });
      offset = $('#' + index).find('td:first').offset();
      height = $('#' + index).height();
      return $('.bar-container').css({
        'top': offset.top + 37 + height * 0.5,
        'left': offset.left - 10
      });
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
            date: item.snippet.publishedAt.slice(0, 10),
            playing: 0
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
      suggestion: Handlebars.compile('<img src="{{imgUrl}}" /><p><strong>{{title}} | {{date}}<strong></p>')
    }
  }).on('typeahead:selected', function(e, suggestion, name) {
    window.Playlist.add(suggestion);
    return window.Playlist.render();
  });
});
