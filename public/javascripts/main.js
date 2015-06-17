jQuery(function() {
  var Playlist, Results, done, onPlayerReady, onPlayerStateChange, stopVideo;
  window.Player = void 0;
  done = false;
  $(document).on('keydown', function(e) {
    var $active, $this;
    $active = $('#playlist .item.active');
    if (!$('.form-control').is(':focus')) {
      if ($active.length) {
        if (e.keyCode === 8 || 46) {
          $('.forBackspace').focus();
          $this = $active.first();
          console.error('???');
          window.Playlist.removeById($this.data('video-id'));
          console.log($this.data('video-id'));
          e.preventDefault();
          e.stopPropagation();
          if ($this.data('video-id' === window.Player.getVideoData().video_id)) {
            $('.bar-container').css({
              'top': -9999,
              'left': -9999
            });
          }
          return false;
        }
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
          return window.Playlist.play(0);
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
      var $playtemplate, index, item, j, len, ref;
      $playtemplate = $('.play-template');
      $('#playlist .item').remove();
      ref = this.list;
      for (j = 0, len = ref.length; j < len; j++) {
        item = ref[j];
        index = _.findIndex(this.list, function(chr) {
          return chr.id === item.id;
        });
        console.log(index);
        $playtemplate = $('#playlist .play-template').clone();
        $playtemplate.find('.playlist-title').html(item.title);
        $playtemplate.find('.playlist-date').html(item.date);
        $playtemplate.data('video-id', item.id);
        $playtemplate.attr('id', index);
        $playtemplate.removeClass('play-template');
        $playtemplate.removeClass('hide');
        $playtemplate.addClass('item');
        $('#playlist tbody').append($playtemplate);
        console.log('from render ' + this.list);
        console.log($playtemplate.data('video-id'));
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
        $('.bar-container').css({
          'top': offset.top + 37 + height * 0.5,
          'left': offset.left - 10
        });
        return window.Playlist.play({
          videoId: $this.data('video-id'),
          suggestedQuality: 'large'
        });
      });
      return window.ShuffledPlaylist = _.shuffle(window.Playlist.get());
    };

    Playlist.prototype.play = function(i) {
      var height, item, j, len, offset, ref;
      window.Player.loadVideoById(this.list[i].id, 0, 'large');
      ref = this.list;
      for (j = 0, len = ref.length; j < len; j++) {
        item = ref[j];
        item.playing = 0;
      }
      this.list[i].playing = 1;
      offset = $("#" + i + "]").find('td:first').offset();
      height = $("#" + i + "]").height;
      return $('.bar-container').css({
        'top': offset.top + 37 + height * 0.5,
        'left': offset.left - 10
      });
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

    Playlist.prototype.remap = function() {
      var i, j, k, mapping, ref, ref1, tempVideos;
      mapping = $("#sortable").sortable("toArray", {
        attribute: "id"
      });
      tempVideos = [];
      for (i = j = 0, ref = this.list.length - 1; 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
        tempVideos[i] = this.list[mapping[i]];
      }
      for (i = k = 0, ref1 = this.list.length - 1; 0 <= ref1 ? k <= ref1 : k >= ref1; i = 0 <= ref1 ? ++k : --k) {
        this.list[i] = tempVideos[i];
      }
      return render();
    };

    return Playlist;

  })();
  window.Playlist = new Playlist();
  window.Playlist.add({
    title: "California Drought Is God’s Punishment For Abortion Laws",
    id: "Kn8_wCGd80g",
    imgUrl: "https://i.ytimg.com/vi/Kn8_wCGd80g/default.jpg",
    date: "2015-06-16"
  });
  window.Playlist.add({
    title: "OMFG - Hello",
    id: "ih2xubMaZWI",
    imgUrl: "https://i.ytimg.com/vi/ih2xubMaZWI/default.jpg",
    date: "2014-12-25"
  });
  window.Playlist.render();
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
    console.log(suggestion);
    window.Playlist.add(suggestion);
    return window.Playlist.render();
  });
});
