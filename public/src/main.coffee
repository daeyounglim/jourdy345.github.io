jQuery ->
  # Messenger.options = {
  #   theme: 'air'
  #   extraClasses: 'messenger-fixed messenger-on-bottom messenger-on-right'
  # }
  # BrowserDetect =
  #   init: ->
  #       @browser = @searchString(@dataBrowser) or "Other";
  #       @version = @searchVersion(navigator.userAgent) or @searchVersion(navigator.appVersion) or "Unknown";

  #   searchString: (data) ->
  #       for datum in data
  #           dataString = datum.string
  #           @versionSearchString = datum.subString

  #           if dataString.indexOf(datum.subString) isnt -1
  #               return datum.identity

  #   searchVersion: (dataString) ->
  #       index = dataString.indexOf @versionSearchString
  #       if index is -1
  #         return

  #       rv = dataString.indexOf "rv:"
  #       if @versionSearchString is "Trident" and rv isnt -1
  #           return parseFloat dataString.substring rv + 3
  #       else
  #         return parseFloat dataString.substring(index + @versionSearchString.length + 1)


  #   dataBrowser: [
  #       {string: navigator.userAgent, subString: "Chrome", identity: "Chrome"},
  #       {string: navigator.userAgent, subString: "MSIE", identity: "Explorer"},
  #       {string: navigator.userAgent, subString: "Trident", identity: "Explorer"},
  #       {string: navigator.userAgent, subString: "Firefox", identity: "Firefox"},
  #       {string: navigator.userAgent, subString: "Safari", identity: "Safari"},
  #       {string: navigator.userAgent, subString: "Opera", identity: "Opera"}
  #   ]

  # BrowserDetect.init()
  # if BrowserDetect.browser is 'Explorer'
  #   Messenger().post
  #     message: 'Oh! I\'m sorry but features are limited on Internet Explorer.'
  #     type: 'error'
  #     showCloseButton: true
  # else
  #   Messenger().post
  #     message: 'Good to see you off Internet Explorer!'
  #     type: 'info'
  #     showCloseButton: true

  window.Player = undefined
  done = false
  # $ ->
  #   $('#sortable').sortable
  #     stop: (event, ui) ->
  #       window.Playlist.remap()
  #       return
  #   $('#sortable').disableSelection()
  #   return

  $ '.behav-buttons i'
      .on 'click', (e) ->
        $this = $ this
        if $this.hasClass 'button-active'
          $this.removeClass 'button-active'
        else
          $this.addClass 'button-active'
          $this.closest('.col-sm-1').siblings().find('i').removeClass('button-active')


  onPlayerReady = (event) ->
    event.target.playVideo()
    return

  onPlayerStateChange = (event) ->
    if event.data is YT.PlayerState.ENDED
      if $('.repeat-all').hasClass 'button-active'
        if window.Player.getVideoData().video_id is window.Playlist.get()[window.Playlist.get().length - 1].youtube_video_id
          window.Playlist.play 0
        else
          currentVideoIndex =  _.findIndex window.Playlist.get(), (chr) ->
            return chr.youtube_video_id is window.Player.getVideoData().video_id
          window.Playlist.play currentVideoIndex + 1
      else if $('.repeat-one').hasClass 'button-active'
        currentVideoIndex =  _.findIndex window.Playlist.get(), (chr) ->
            return chr.youtube_video_id is window.Player.getVideoData().video_id
        window.Playlist.play currentVideoIndex
      else if $('.shuffle').hasClass 'button-active'
        currentVideoIndex =  _.findIndex window.ShuffledPlaylist, (chr) ->
          return chr.youtube_video_id is window.Player.getVideoData().video_id
        delete window.ShuffledPlaylist[currentVideoIndex]
        window.ShuffledPlaylist = _.compact window.ShuffledPlaylist
        if window.ShuffledPlaylist.length
          i = _.findIndex window.Playlist.get(), (chr) ->
            return chr.youtube_video_id is window.ShuffledPlaylist[0].youtube_video_id
          window.Playlist.play i
        else
          window.ShuffledPlaylist = _.shuffle window.Playlist.get()
          i = Math.floor(Math.random()*window.Playlist.get().length)
          window.Playlist.play i
      else
        currentVideoIndex =  _.findIndex window.Playlist.get(), (chr) ->
          return chr.youtube_video_id is window.Player.getVideoData().video_id
        window.Playlist.play currentVideoIndex+1


  stopVideo = ->
    window.Player.stopVideo()
    return

  window.onYouTubeIframeAPIReady = ->
    window.Player = new YT.Player 'player',
      height: '200'
      width: '300'
      videoId: ''
      playerVars:
        'autoplay': 1
        'controls': 1
      events:
        'onStateChange': onPlayerStateChange
    width = $('.main-playlist').width()
    window.Player.setSize(width, width*9/16)
    return


  $(window)
    .on 'resize', (e) ->
      width = $('.main-playlist').width()
      window.Player.setSize(width, width*9/16)



  ## Create a class to wrap all the functions needed when controlling the playlist
  class Playlist
    constructor: (@list, @bucket_list) ->
      # unless @list
      #   @list = []
      @bucket_list = []
      @list = if localStorage.videos then JSON.parse(localStorage.videos) else []
      @render() if @list.length
      # for video in videos
      #   @add video
    set: (list) ->
      @list = list
    get: ->
      @list
    add: (item) ->
      # {
      #   id: 'movie id'
      #   title: '...'
      # }
      @list.push item
      console.log 'item: ' + item
      video = JSON.stringify([item])
      localStorage.videos = JSON.stringify @list
      if $('.main-playlist').attr('data-playlist-id')
        id = $('.main-playlist').attr('data-playlist-id')
        $.ajax
          url: '/video/add'
          method: 'post'
          data:
            playlist_id: id
            video_list: video
          success: (d, s, x) ->
            console.log x.status
            console.log d
          error: (x, s, d) ->
            console.log d, s
        return true


    add_to_next: (item) ->
      @list.unshift item

    render: ->
      $ '#playlist .item'
        .remove()

      for item, i in @list
        $playtemplate = $('#playlist .play-template').clone()
        $playtemplate
          .find '.col-sm-1:first'
          .html i+1
        if item.video_title?.length > 35
          $playtemplate
            .find '.col-md-9'
            .html item.video_title[0..35] + '...'
        else
          $playtemplate
            .find '.col-md-9'
            .html item.video_title
        if _.has(@list[0], 'id')
          $playtemplate
            .data 'video-index', item.id
            .attr 'data-video-index', item.id
        $playtemplate
          .data 'video-id', item.youtube_video_id
        $playtemplate
          .attr 'id', i
        $playtemplate
          .attr 'data-video-id', item.youtube_video_id
        $playtemplate
          .attr 'data-thumbnail', item.imgUrl

        $playtemplate.removeClass 'play-template'
        $playtemplate.removeClass 'hide'
        $playtemplate.addClass 'item'
        $ '#playlist'
          .append $playtemplate


      $ '#playlist .item .icon-play'
        .on 'click', (e) ->
          console.log '>>'
          $this = $ this
          $item = $this.closest '.item'
          window.Playlist.play $item.attr('id')
      $ '#playlist .item .icon-minus'
        .on 'click', (e) ->
          console.log '>>>'
          $this = $ this
          $item = $this.closest('.item')
          i = +$item.attr('id')
          window.Playlist.remove(i)
      window.ShuffledPlaylist = _.shuffle @get()
      # $.ajax
      #   url: '/video/add'
      #   method: 'post'
      #   data:
      #     video_list: JSON.stringify(@get())
      #   success: (d, s, x) ->
      #     console.log x.status
      #     console.log d
      #   error: (x, s, d) ->
      #     console.log s, d
      # return true

    play: (i) ->
      ++@list[i].play_count
      window.Player.loadVideoById @list[i].youtube_video_id, 0, 'large'
      if $('.main-playlist').attr('data-playlist-id')
        id = $('.main-playlist').attr('data-playlist-id')
        $.ajax
          url: "/update/playcount/#{id}"
          method: 'post'
          data:
            video: JSON.stringify(@list[i])
          success: (d, s, x) ->
            console.log x.status
          error: (x, s, d) ->
            console.log s, d
        return false

    remove: (i) ->
      if $('.main-playlist').attr('data-playlist-id')
        id = $('.main-playlist').attr('data-playlist-id')
        $.ajax
          url: "/video/delete/#{id}"
          method: 'post'
          data:
            video: JSON.stringify(@list[i])
          success: (d, s, x) ->
            console.log x.status
            console.log d
          error: (x, s, d) ->
            console.log d, s
      @list.splice(i, 1)
      @render()
      localStorage.videos = JSON.stringify @list

    clear: ->
      @list = []
      @render()
      $ '.bar-container'
        .css
          'top': -9999
          'left': -9999
      localStorage.videos = JSON.stringify @list

    remap: ->
      mapping = _.compact($("#sortable").sortable("toArray", {attribute: "id"}))
      tempPlaylist = []
      tempPlaylist[i] = @list[mapping[i]] for i in [0..(@list.length-1)]
      @list[i] = tempPlaylist[i] for i in [0..(@list.length-1)]
      window.Playlist.render()
      # index = _.findIndex @list, (chr) ->
      #   return chr.youtube_video_id is window.Player.getVideoData().video_id
      # offset = $('#'+index).find('td:first').offset()
      # height = $('#'+index).height()
      # $ '.bar-container'
      #   .css
      #     'top': offset.top + 37 + height * 0.5
      #     'left': offset.left - 10
    add_to_bucket_list: (item) ->
      @bucket_list.push(item)
    remove_from_bucket_list: (i) ->
      @bucket_list.splice(i,1)
    show_bucket_list: ->
      return @bucket_list
  window.Playlist = new Playlist()


  $ '.video-search-form'
    .on 'submit', (e) ->
      $this = $ this
      __QUERY__ = $this.find('input').val()
      if __QUERY__.trim().length is 0
        e.preventDefault()
        e.stopPropagation()
        return alert 'Please insert a search string'
      $.ajax
        url: "https://www.googleapis.com/youtube/v3/search?q=#{__QUERY__}&part=snippet&maxResults=50&type=video&key=AIzaSyCImmWz0DcJdeD45YTwGB_ZmhNv167bwpM"
        method: 'get'
        success: (d, s, x) ->
          console.log x.status
          $ '.when-no-result'
            .addClass 'hide'
          $ '.video-search-title'
            .removeClass 'hide'
            .html 'Results for ' + '<em>" ' +  __QUERY__ + ' "</em>'
          $ '.video-search-result'
            .remove()
          for item in d.items
            index = _.findIndex d.items, (chr) ->
              return chr.id.videoId is item.id.videoId
            $template = $('.video-search-result-template').clone()
            $template
              .find 'img'
              .attr 'src', item.snippet.thumbnails.default.url
            $template
              .find '.col-md-1:first'
              .html index+1
            $template
              .find '.col-md-7'
              .html item.snippet.title
            $template
              .data 'video-id', item.id.videoId
            $template
              .attr 'data-video-id', item.id.videoId
            $template
              .attr 'data-thumbnail', item.snippet.thumbnails.default.url
            $template
              .attr 'data-title', item.snippet.title
            $template
              .removeClass 'hide'
              .addClass 'animated fadeInUp'
            $template
              .removeClass 'video-search-result-template'
            $template
              .addClass 'video-search-result'
            $ '.video-search-results'
              .append $template
          $ '.video-search-result .add-video'
            .on 'click', (e) ->
              $this = $ this
              $item = $this.closest '.video-search-result'
              window.Playlist.add
                youtube_video_id: $item.data 'video-id'
                video_title: $item.find('.col-md-7').html()
                imgUrl: $item.find('img').attr('src')
                play_count: 0
              window.Playlist.render()
          $ '.video-search-result .play-video'
            .on 'click', (e) ->
              $this = $ this
              $item = $this.closest '.video-search-result'
              window.Player.loadVideoById($item.data('video-id'), 'large')
        error: (x, s, d) ->
          console.log s, d
      return false

  $(window).on 'get.videos.from.playlist', (e, id, callback) ->
    $.ajax
      url: "/playlist/#{id}/videos"
      method: 'get'
      success: (d, s, x) ->
        console.log x.status
        console.log d
        $('.main-playlist')
          .data 'playlist-id', id
          .attr 'data-playlist-id', id
        window.Playlist.set(d)
        window.Playlist.render()
      error: (x, s, d) ->
        console.log s, d
    return callback() if callback


  $ '.delete-all'
    .on 'click', (e) ->
      if window.Playlist.get().length
        if confirm 'This cannot be undone. Do you want to proceed?'
          window.Playlist.clear()
          return true
        else
          e.preventDefault()
          return false
      else
        alert 'There\'s nothing to delete.'
  $ '.btn-related-videos'
    .on 'click', (e) ->
      currentVideoId = window.Player.getVideoData().video_id
      if currentVideoId
        $.ajax
          url: 'https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=50&key=AIzaSyCImmWz0DcJdeD45YTwGB_ZmhNv167bwpM&relatedToVideoId=' + currentVideoId
          method: 'get'
          success: (d, s, x) ->
            for item in d.items
              $template = $('.related-template').clone()
              $template
                .find '.related-img'
                .attr 'src', item.snippet.thumbnails.default.url
              $template
                .find '.related-title'
                .html item.snippet.title
              $template
                .find '.related-description'
                .html item.snippet.description
              $template
                .data 'video-id', item.id.videoId
              $template
                .attr 'data-video-id', item.id.videoId
              $template
                .data 'video-title', item.snippet.title
              $template
                .data 'video-date', item.snippet.publishedAt[0..9]
              $template
                .addClass 'related-item'
              $template
                .removeClass 'hide'
              $template
                .removeClass 'related-template'
              $ '#myrelatedModal .related-body'
                .append $template
            $ '.related-item'
              .on 'click', (e) ->
                $this = $ this
                window.Playlist.add
                  youtube_video_id: $this.data 'video-id'
                  video_title: $this.data 'video-title'
                window.Playlist.render()
            true
          error: (x, s, d) ->
            alert x.status
            e.preventDefault()
            e.stopPropagation()
            false
      else
        e.preventDefault()
        e.stopPropagation()
        alert 'No running video.'


  $ '#signinModal'
    .on 'shown.bs.modal', (e) ->
      $ '#signinModal #UserID'
        .focus()


  $ '#signup-ConfirmPassword'
    .on 'keyup', (e) ->
      $this = $ this
      if $this.val() isnt $('.sign-up-container #signup-UserPassword').val()
        $ '.password-check'
          .removeClass 'hide'
      else
        $ '.password-check'
          .addClass 'hide'

  $ '.sign-up-container button'
    .on 'click', (e) ->
      if $('#signup-ConfirmPassword').val() isnt $('#signup-UserPassword').val()
        e.preventDefault()
        e.stopPropagation()
        alert 'Passwords do not match.'
        $('#signup-ConfirmPassword').focus()

  $(window).on 'get.playlists', (e, callback) ->
    $.ajax
      url: '/playlist'
      method: 'get'
      async: false
      success: (d, s, x) ->
        console.log d
        # clean
        $ '.playlist-item'
          .remove()
        for each, i in d
          $template = $('.playlist-slide').clone()
          $template
            .find '.col-md-1:first'
            .html i+1
          $template
            .find '.col-md-10'
            .html each.playlist_name
          $template
            .data 'playlist-id', each.id
            .attr 'data-playlist-id', each.id
          $template
            .removeClass 'playlist-slide hide'
            .addClass 'playlist-item'
          $ '#playlist'
            .append $template
        $ '.playlist-item .col-md-10'
          .on 'click', (e) ->
            $this = $ this
            $item = $this.closest '.playlist-item'
            $id = $item.data('playlist-id')
            after_getting_videos_from_playlist = ->
              $ '.main-playlist'
                .find '.col-md-10'
                .html $item.find('.col-md-10').html()
              $('.main-playlist').find('.icon-plus').addClass('hide')
              $('.playlist-playlist-menu').addClass('hide')
              $ '.main-playlist'
                .removeClass 'hide'
              $ '.playlist-item'
                .addClass 'hide'
              $ '.item'
                .addClass 'animated fadeInUp'
            $(window).trigger 'get.videos.from.playlist', [$id, after_getting_videos_from_playlist]
        $ '.playlist-item .icon-minus'
          .on 'click', (e) ->
            $this = $ this
            $item = $this.closest('.playlist-item')
            id = $item.attr('data-playlist-id')
            $.ajax
              url: "/playlist/delete/#{id}"
              method: 'post'
              success: (d, s, x) ->
                console.log x.status
                console.log d
                $(window).trigger 'get.playlists'
              error: (x, s, d) ->
                console.log s, x
            return true
      error: (x, s, d) ->
        console.log s, d
    return callback() if callback



  # get Playlists
  $ '.main-playlist .icon-block-menu'
    .on 'click', (e) ->
      unless window.Session.user
        return alert 'Please sign in for more features!'
      after_getting_playlists = ->
        console.log '>>??'
        if not $('.add-playlist').hasClass('hide')
          $('.add-playlist').addClass('hide')
        if not $('.item').hasClass('hide')
          $('.item').addClass('hide')
        $ '.playlist-item'
          .addClass 'animated fadeInUp'
        $ '.main-playlist'
          .addClass 'hide'
        $ '.playlist-playlist-menu'
          .removeClass 'hide'
      $(window).trigger 'get.playlists', [after_getting_playlists]

  $ '.playlist-playlist-menu .icon-music'
    .on 'click', (e) ->
      window.Playlist.set JSON.parse(localStorage.videos or '[]')
      window.Playlist.render()
      if not $('.add-blank-playlist').hasClass('hide')
        $('.add-blank-playlist').addClass('hide')
      if not $('.playlist-item').hasClass('hide')
        $('.playlist-item').addClass('hide')
      $ '#playlist .item'
        .removeClass 'hide'
        .addClass 'animated fadeInUp'
      $ '.playlist-playlist-menu'
        .addClass 'hide'
      $ '.main-playlist'
        .removeClass 'hide'
      if window.Player.getPlayerState() == 1 or window.Player.getPlayerState() == 2
        i = _.findIndex window.Playlist.get(), (chr) ->
          return chr.youtube.video_id == window.Player.getVideoData().video_id
        return window.Playlist.getEqualizer(i)


  $ '.add-blank-playlist-button'
    .on 'click', (e) ->
      $ '.bar-container'
        .css
          top: -9999
          left: -9999
      $ '.playlist-playlist-menu'
        .addClass 'hide'
      $ '.playlist-playlist-menu-2'
        .removeClass 'hide'
      $ '.playlist-item'
        .addClass 'hide'
      $ '.add-blank-playlist'
        .removeClass 'hide'
      $ '.add-blank-playlist .row'
        .addClass 'animated fadeInUp'
  $ '.playlist-playlist-menu-2 .icon-block-menu'
    .on 'click', (e) ->
      $ '.playlist-playlist-menu-2'
        .addClass 'hide'
      $ '.playlist-playlist-menu'
        .removeClass 'hide'
      $ '.add-blank-playlist'
        .addClass 'hide'
      $ '.playlist-item'
        .removeClass 'hide'
        .addClass 'animated fadeInUp'

  $ '.playlist-playlist-menu-2 .icon-music'
    .on 'click', (e) ->
      $ '.playlist-playlist-menu-2'
        .addClass 'hide'
      $ '.main-playlist'
        .removeClass 'hide'
      $ '.add-blank-playlist'
        .addClass 'hide'
      $ '.item'
        .removeClass 'hide'
        .addClass 'animated fadeInUp'
      if window.Player.getPlayerState() == 1 or window.Player.getPlayerState() == 2
        i = _.findIndex window.Playlist.get(), (chr) ->
          return chr.youtube.video_id == window.Player.getVideoData().video_id
        return window.Playlist.getEqualizer(i)



  $(window).on 'add.blank.playlist', (e, callback) ->
    if $('.add-blank-playlist input').val().trim().length is 0
      return alert 'Please make a name for the Playlist.'
    $.ajax
      url: '/playlist/add/blank'
      method: 'post'
      data:
        blank_playlist_name: $('.add-blank-playlist input').val()
      headers:
        Accept: 'application/json'
      success: (d, s, x) ->
        console.log d
        if x.status isnt 200
          return 'Error'
        true
      error: (x, s, d) ->
        console.log s, d
    return callback() if callback
  $('.add-blank-playlist form')
    .on 'submit', (e) ->
      e.preventDefault()
      e.stopPropagation()
      after_adding_blank_playlist = ->
        $ '.add-blank-playlist-success'
          .removeClass 'hide'
          .addClass 'animated fadeInUp'
        setTimeout ->
          $('.add-blank-playlist-success').addClass('animated fadeOutDown')
        , 2000
        setTimeout ->
          $('.add-blank-playlist-success').addClass('hide').removeClass('animated fadeOutDown fadeInUp')
        , 3500
      $(window).trigger 'add.blank.playlist', [after_adding_blank_playlist]



  $(window).on 'render.playlist', (e, collection, callback) ->
    # render items from collection
    $ '.add-videos-item'
      .remove()
    for each, i in collection
      $template = $('.add-playlist .pending-videos').clone()
      $template
        .find '.col-md-1:first'
        .html i+1
      if each.video_title.length > 40
        $template
          .find '.col-md-9'
          .html each.video_title[0..39] + '...'
      else
        $template
          .find '.col-md-9'
          .html each.video_title
      $template
        .attr 'id', i
      $template
        .removeClass 'pending-videos hide'
        .addClass 'add-videos-item'
      $ '.add-playlist .col-md-12:first'
        .append $template

    $ '.add-videos-item .icon-minus'
      .on 'click', (e) ->
        $this = $ this
        $item = $this.closest '.add-videos-item'
        index = +$item.attr('id')
        window.Playlist.remove_from_bucket_list(index)
        $(window).trigger 'render.playlist', [window.Playlist.show_bucket_list()]
    return callback() if callback

  $ '.add-playlist-button'
    .on 'click', (e) ->
      unless window.Session.user
        return alert 'Please sign in to save Playlists'
      window.Playlist.show_bucket_list().splice(0,window.Playlist.show_bucket_list().length)
      for each in window.Playlist.get()
        window.Playlist.add_to_bucket_list(each)
      after_render = ->
        $ '.main-playlist'
          .addClass 'hide'
        $ '.main-playlist-2'
          .removeClass 'hide'
        $ '.item'
          .addClass 'hide'
        $ '.add-playlist'
          .removeClass 'hide'
        $ '.add-playlist .row'
          .addClass 'animated fadeInUp'

      $(window).trigger 'render.playlist', [window.Playlist.show_bucket_list(), after_render]

  $ '.main-playlist-2 .icon-music'
    .on 'click', (e) ->
      $ '.main-playlist-2'
        .addClass 'hide'
      $ '.main-playlist'
        .removeClass 'hide'
      $ '.add-playlist'
        .addClass 'hide'
      $ '.item'
        .removeClass 'hide'
        .addClass 'animated fadeInUp'
  $ '.main-playlist-2 .icon-block-menu'
    .on 'click', (e) ->
      $.ajax
        url: '/playlist'
        method: 'get'
        success: (d, s, x) ->
          # clean
          $ '.playlist-item'
            .remove()
          for each, i in d
            $template = $('.playlist-slide').clone()
            $template
              .find '.col-md-1:first'
              .html i+1
            $template
              .find '.col-md-10'
              .html each.playlist_name
            $template
              .data 'playlist-id', each.id
              .attr 'data-playlist-id', each.id
            $template
              .removeClass 'playlist-slide'
              .addClass 'playlist-item'
            $ '#playlist'
              .append $template
          if not $('.add-playlist').hasClass('hide')
            $('.add-playlist').addClass('hide')
          if not $('.item').hasClass('hide')
            $('.item').addClass('hide')
          $ '.playlist-item'
            .removeClass 'hide'
            .addClass 'animated fadeInUp'
          $ '.main-playlist-2'
            .addClass 'hide'
          $ '.playlist-playlist-menu'
            .removeClass 'hide'
          $ '.add-playlist'
            .addClass 'hide'



          $ '.playlist-item .col-md-10'
            .on 'click', (e) ->
              $this = $ this
              $item = $this.closest '.playlist-item'
              $id = $item.data('playlist-id')
              after_getting_videos_from_playlist = ->
                $ '.main-playlist'
                  .find '.col-md-10'
                  .html $item.find('.col-md-10').html()
                $('.main-playlist').find('.icon-plus').addClass('hide')
                $('.playlist-playlist-menu').addClass('hide')
                $ '.main-playlist'
                  .removeClass 'hide'
                $ '.playlist-item'
                  .addClass 'hide'
                $ '.item'
                  .addClass 'animated fadeInUp'
              $(window).trigger 'get.videos.from.playlist', [$id, after_getting_videos_from_playlist]
          true
        error: (x, s, d) ->
          alert 'Error: ' + s

    $ '.add-playlist form'
      .on 'submit', (e) ->

  $(window).on 'add.playlist', (e, collection, callback) ->
    $.ajax
      url: '/playlist/add/new'
      method: 'post'
      headers:
        Accept: 'application/json'
      data:
        playlist_name: $('.add-playlist input').val()
      success: (d, s, x) ->
        console.log d
        if x.status isnt 200
          return 'Error'
        $.ajax
          url: '/video/add'
          method: 'post'
          contentType: 'application/json'
          data: JSON.stringify {
            playlist_id: d.insertId
            video_list: collection
          }
          dataType: 'application/json'
          headers:
            Accept: 'application/json'
          success: (d, s, x) ->
            if x.status isnt 200
              return 'Error'
            true
          error: (x, s, d) ->
            console.log s, d
        true
      error: (x, s, d) ->
        console.log s, d
    return callback() if callback
  $ '.add-playlist form'
    .on 'submit', (e) ->
      e.preventDefault()
      e.stopPropagation()
      if $('.add-playlist input').val().trim().length == 0
        return alert 'Please make a name for the Playlist.'
      after_adding_playlist = ->
        $ '.add-playlist-success'
          .removeClass 'hide'
          .addClass 'animated fadeInRight'
        setTimeout ->
          $('.add-playlist-success').addClass('animated fadeOutRight')
        , 2000
        setTimeout ->
          $('.add-playlist-success').addClass('hide').removeClass('animated fadeInRight fadeOutRight')
        , 3500
      $(window).trigger 'add.playlist', [window.Playlist.show_bucket_list(), after_adding_playlist]
