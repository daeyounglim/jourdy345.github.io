jQuery ->

  window.Player = undefined
  done = false
  $(document)
    .on 'keydown', (e) ->
      $active = $ '#playlist .item.active'
      if $active.length
        if e.keyCode is 8
          $ '.forBackspace'
            .focus()
          $this = $active.first()
          window.Playlist.removeById($this.data 'video-id')
          window.Playlist.render()
          e.preventDefault()
          e.stopPropagation()
          return false

  onPlayerReady = (event) ->
    event.target.playVideo()
    return

  onPlayerStateChange = (event) ->
    # if event.data is YT.PlayerState.PLAYING and !done
    #   setTimeout stopVideo, 1000
    #   done = true
    if event.data is YT.PlayerState.ENDED
      console.log 'the video ended'

      currentVideoIndex =  _.findIndex window.Playlist.get(), (chr) ->
        return chr.id is window.Player.getVideoData().video_id
      console.log '>>', currentVideoIndex
      window.Player.loadVideoById 
        videoId: window.Playlist.get()[currentVideoIndex + 1].id
        suggestedQuality: 'large'
      # window.Player.playVideo()


  stopVideo = ->
    window.Player.stopVideo()
    return

  window.onYouTubeIframeAPIReady = ->
    console.log 'CALL'
    window.Player = new YT.Player 'player',
      height: '631.8'
      width: '1036.8'
      videoId: 'M7lc1UVf-VE'
      playerVars:
        'autoplay': 1
        'controls': 2
      events:
        # 'onReady': onPlayerReady
        'onStateChange': onPlayerStateChange
    return

  ## Create a class to wrap all the functions needed when controlling the playlist
  class Playlist
    constructor: (@list) ->
      unless @list
        @list = []
    get: ->
      @list

    add: (item) ->
      # {
      #   id: 'movie id'
      #   title: '...'
      # }
      @list.push item

    add_to_next: (item) ->
      @list.unshift item

    check: (item) ->
      for each in @list
        templist = JSON.stringify @list, null, '  '
        if templist.match item.id
          console.log 'from check !!' + item.id
          return true
        return false


    remove: (item) ->
      
    render: ->
      $playtemplate = $ '.play-template'

      $ '#playlist .item'
        .remove()

      for item in @list
        $playtemplate = $('#playlist .play-template').clone()
        $playtemplate
          .find '.playlist-title'
          .html item.title
        $playtemplate
          .find '.playlist-videoId'
          .html item.id
        $playtemplate
          .data 'video-id', item.id
        $playtemplate.on 'dblclick', (e) ->
          $this = $ this
          $video_id = item.id
          window.Player.loadVideoById $video_id, 'large'
        $playtemplate.removeClass 'play-template'
        $playtemplate.removeClass 'hide'
        $playtemplate.addClass 'item'
        $ '#playlist tbody'
          .append $playtemplate
        console.log 'from render ' + @list
        console.log $playtemplate.data 'video-id'
        true

      $ '#playlist .item'
        .on 'click', (e) ->
          $this = $ this
          $this.addClass 'active'
          $this.siblings().removeClass 'active'
          # $this = $ this
          # return true unless $this.is '.active'
          # if e.keyCode is 8
          #   window.Playlist.removeById($this.data 'video-id')
          #   window.Playlist.render()
          # e.preventDefault()
          # e.stopPropagation()
          # return false

      # $ '#playlist .active'
      #   .on 'keydown', (e) ->
      #     $this = $ this
      #     console.log '>>>', e, e.which
      #     if e.keyCode is 8
      #       e.preventDefault()
      #       window.Playlist.removeById($this.data 'video-id')
      #       window.Playlist.render()

    play: (item) ->
      window.Player.loadVideoById 
        id: item.id
        suggestedQuality: 'large'
      true

    removeById: (id) ->
      index = _.findIndex @list, (chr) ->
        return chr.id = id
      delete @list[index]
      _.compact @list
      window.Playlist.render()
  window.Playlist = new Playlist()
  
  Results = new Bloodhound 
    datumTokenizer: (d) ->
      Bloodhound.tokenizers.whitespace(d.title)
    queryTokenizer: Bloodhound.tokenizers.whitespace
    limit: 50
    remote: 
      url: "https://www.googleapis.com/youtube/v3/search?q=__QUERY__&part=snippet&maxResults=50&type=video&key=AIzaSyCImmWz0DcJdeD45YTwGB_ZmhNv167bwpM"
      wildcard: '__QUERY__'
      filter: (response) ->
        data = []
        for item in response.items
          data.push {
            title: item.snippet.title
            id: item.id.videoId
            imgUrl: item.snippet.thumbnails.default.url
          }
        return data
  
  Results.initialize()
  $ '#bloodhound .typeahead'
    .typeahead 
      limit: 5
      minLength: 1
      highlight: true
    , 
      name: 'searchYoutube'
      # displayKey: 'subtitle'
      minLength: 1
      highlight: true
      valueKey: 'name'
      source: Results.ttAdapter()
      templates: 
        suggestion: Handlebars.compile '<img src="{{imgUrl}}" /><p><strong>{{title}} | {{id}}<strong></p>'
        # suggestion: (data) ->
        #   console.log '>>', data
        #   return Handlebars.compile '<p><strong>{{title}} - {{id}}<strong></p>', data
        # # suggestion: Handlebars.compile '<p><strong>{{title}} - {{id}}<strong></p>'
    .on 'typeahead:selected', (e, suggestion, name) ->
      window.Playlist.add suggestion
      window.Playlist.render()


  













