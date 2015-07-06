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
  $(document)
    .on 'keydown', (e) ->
      $active = $ '#playlist .item.active'
      $this = $active.first()
      if e.shiftKey
        if e.keyCode is 8
          if $this.attr('data-video-id') is window.Player.getVideoData().video_id
            alert "Cannot delete currently running video."
          else
            window.Playlist.remove($this.attr('id'))
            i = _.findIndex window.Playlist.get(), (chr) ->
              return chr.id is window.Player.getVideoData().video_id
            offset = $('#' + i).find('td:first').offset()
            height = $('#' + i).height()
            $ '.bar-container'
              .css
                'top': offset.top + 37 + height * 0.5
                'left': offset.left - 10
        return true
      return true
  $ ->
    $('#sortable').sortable
      stop: (event, ui) ->
        window.Playlist.remap()
        return
    $('#sortable').disableSelection()
    return

  $ '.playlist-button button'
      .on 'click', (e) ->
        $this = $ this
        if $this.hasClass 'button-active'
          $this.removeClass 'button-active'
        else
          $this.addClass 'button-active'
          $this.siblings().removeClass 'button-active'


  onPlayerReady = (event) ->
    event.target.playVideo()
    return

  onPlayerStateChange = (event) ->
    if event.data is YT.PlayerState.ENDED
      if $('.playlist-button .repeat-all').hasClass 'button-active'
        if window.Player.getVideoData().video_id is window.Playlist.get()[window.Playlist.get().length - 1].youtube_video_id
          window.Playlist.play 0
        else
          currentVideoIndex =  _.findIndex window.Playlist.get(), (chr) ->
            return chr.youtube_video_id is window.Player.getVideoData().video_id
          window.Playlist.play currentVideoIndex + 1
      else if $('.playlist-button .repeat-one').hasClass 'button-active'
        currentVideoIndex =  _.findIndex window.Playlist.get(), (chr) ->
            return chr.youtube_video_id is window.Player.getVideoData().video_id
        window.Playlist.play currentVideoIndex
      else if $('.playlist-button .shuffle').hasClass 'button-active'
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
    constructor: (@list) ->
      # unless @list
      #   @list = []
      
      @list = JSON.parse(localStorage.videos or '[]')
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
      
      localStorage.videos = JSON.stringify @list
    add_to_next: (item) ->
      @list.unshift item
      
    render: ->
      $ '#playlist .item'
        .remove()

      for item in @list
        index = _.findIndex @list, (chr) ->
          return chr.youtube_video_id is item.youtube_video_id
        $playtemplate = $('#playlist .play-template').clone()
        $playtemplate
          .find '.col-sm-1:first'
          .html index+1
        if item.video_title.length > 40
          $playtemplate
            .find '.col-md-9'
            .html item.video_title[0..39] + '...'
        else
          $playtemplate
            .find '.col-md-9'
            .html item.video_title
        $playtemplate
          .data 'video-id', item.youtube_video_id
        $playtemplate
          .attr 'id', index
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
          $this = $ this
          $item = $this.closest '.item'
          window.Playlist.play $item.attr 'id'
      $ '#playlist .item .icon-cross'
        .on 'click', (e) ->
          $this = $ this
          $item = $this.closest '.item'
          window.Playlist.remove $item.attr 'id'
      
      
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
      # for item in @list
      #   item.playing = 0
      # @list[i].playing = 1
      # offset = $("#" + i).find('td:first').offset()
      # height = $("#" + i).height()
      # $ '.bar-container'
      #   .css
      #     'top': offset.top + 37 + height * 0.5
      #     'left': offset.left - 10
      window.Player.loadVideoById @list[i].youtube_video_id, 0, 'large'


    remove: (i) ->
      delete @list[i]
      @list = _.compact @list
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
              window.Playlist.render()
          $ '.video-search-result .play-video'
            .on 'click', (e) ->
              $this = $ this
              $item = $this.closest '.video-search-result'
              window.Player.loadVideoById $item.data 'video-id', 'large'
        error: (x, s, d) ->
          console.log s, d
      return false

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

  # get Playlists
  $ '.main-playlist .icon-block-menu'
    .on 'click', (e) ->
      unless window.Session.user
        return alert 'Please sign in for more features!'
      $.ajax
        url: '/playlist'
        method: 'get'
        success: (d, s, x) ->
          # clean
          $ '.playlist-item'
            .remove()
          for each, i in d
            console.log each
            $template = $('.playlist-slide').clone()
            $template
              .find '.col-md-1:first'
              .html i+1
            $template
              .find '.col-md-10'
              .html each.playlist_name
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
          $ '.main-playlist'
            .addClass 'hide'
          $ '.playlist-playlist-menu'
            .removeClass 'hide'
          true
        error: (x, s, d) ->
          alert 'Error: ' + s

  $ '.icon-music'
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

  $ '.add-blank-playlist-button'
    .on 'click', (e) ->
      $ '.playlist-item'
        .addClass 'hide'
      $ '.add-blank-playlist'
        .removeClass 'hide'
        .addClass 'animated fadeInUp'


  $('.add-blank-playlist form')
    .on 'submit', (e) ->
      e.preventDefault()
      e.stopPropagation()
      if $('#newBlankPlaylistName').val().trim().length is 0
        return alert 'Please make a name for the Playlist.'
        
      $.ajax
        url: '/playlist/add/blank'
        method: 'post'
        data:
          blank_playlist_name: $('#newBlankPlaylistName').val()
        headers:
          Accept: 'application/json'
        success: (d, s, x) ->
          console.log d
          if x.status isnt 200
            return 'Error'
          # clean
          $ '.playlist-item'
            .remove()
          for each, i in d
            console.log each
            $template = $('.playlist-slide').clone()
            $template
              .find '.col-md-1:first'
              .html i+1
            $template
              .find '.col-md-10'
              .html each.playlist_name
            $template
              .removeClass 'playlist-slide hide'
              .addClass 'playlist-item'
            $ '#playlist'
              .append $template
          $('#addBlankPlaylistModal').modal('hide')

          true
        error: (x, s, d) ->
          console.log s, d

  $ '.add-playlist-button'
    .on 'click', (e) ->
      list = window.Playlist.get()
      $ '.add-videos-item'
        .remove()
      for each, i in list
        $template = $('.add-playlist .pending-videos').clone()
        $template
          .find '.col-md-1:first'
          .html i+1
        $template
          .find '.col-md-10'
          .html each.video_title
        $template
          .attr 'id', i
        $template
          .removeClass 'pending-videos hide'
          .addClass 'add-videos-item'
        $ '.add-playlist'
          .append $template
      $ '.item'
        .addClass 'hide'
      $ '.add-playlist'
        .removeClass 'hide'
        .addClass 'animated fadeInUp'
  
  $ '#addNewPlaylistModal .icon-minus'
    .on 'click', (e) ->
      console.log '>>>'
      $this = $ this
      $item = $this.closest '.add-videos-item'
      list = window.Playlist.get().slice(0)
      index = $item.attr('id')
      console.log index
      delete list[index]
      list = _.compact list
      $ '.add-videos-item'
        .remove()
      for each, i in list
        $template = $('#addNewPlaylistModal .pending-videos').clone()
        $template
          .find '.col-md-1:first'
          .html i+1
        $template
          .find '.col-md-10'
          .html each.video_title
        $template
          .attr 'id', i
        $template
          .removeClass 'pending-videos hide'
          .addClass 'add-videos-item'
        $ '#addNewPlaylistModal .modal-body'
          .append $template
        $ '#addNewPlaylistModal'
          .modal 'show'

      # $.ajax
      #   url: '/playlist/add'
      #   method: 'post'
      #   data: 
      #     playlist_name: $('#createPlaylist-input').val()
      #     video_list: JSON.stringify(window.Playlist.get())
      #   headers: 
      #     Accept: 'application/json'
      #   success: (d, s, x) ->
      #     console.log d
      #     if x.status isnt 200
      #       return 'Error'

      #     true
      #   error: (x, s, d) ->
      #     console.log s, d



