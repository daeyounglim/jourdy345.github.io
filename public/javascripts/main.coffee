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
          e.preventDefault()
          e.stopPropagation()
          return false
 
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
        if window.Player.getVideoData().video_id is window.Playlist.get()[window.Playlist.get().length - 1].id
          console.log 'from repeat-all'
          window.Playlist.play 
            videoId: window.Playlist.get()[0].id
            suggestedQuality: 'large'
        else
          currentVideoIndex =  _.findIndex window.Playlist.get(), (chr) ->
            return chr.id is window.Player.getVideoData().video_id
          console.log '>>', currentVideoIndex
          window.Playlist.play 
            videoId: window.Playlist.get()[currentVideoIndex + 1].id
            suggestedQuality: 'large'
      else if $('.playlist-button .repeat-one').hasClass 'button-active'
        console.log 'from repeat-one'
        window.Playlist.play 
          videoId: window.Player.getVideoData().video_id
          suggestedQuality: 'large'
      else if $('.playlist-button .shuffle').hasClass 'button-active'
        console.log 'from shuffle'
        currentVideoIndex =  _.findIndex window.ShuffledPlaylist, (chr) ->
          return chr.id is window.Player.getVideoData().video_id
        delete window.ShuffledPlaylist[currentVideoIndex]
        window.ShuffledPlaylist = _.compact window.ShuffledPlaylist
        if window.ShuffledPlaylist.length
          window.Playlist.play 
            videoId: window.ShuffledPlaylist[0].id
            suggestedQuality: 'large'
        else
          window.ShuffledPlaylist = _.shuffle window.Playlist.get()
          i = Math.floor(Math.random()*window.Playlist.get().length)
          window.Playlist.play
            videoId: window.Playlist.get()[i].id
            suggestedQuality: 'large'
      else
        console.log 'from no nothing'
        currentVideoIndex =  _.findIndex window.Playlist.get(), (chr) ->
          return chr.id is window.Player.getVideoData().video_id
        console.log '>>', currentVideoIndex
        window.Playlist.play 
          videoId: window.Playlist.get()[currentVideoIndex + 1].id
          suggestedQuality: 'large'


  stopVideo = ->
    window.Player.stopVideo()
    return

  window.onYouTubeIframeAPIReady = ->
    console.log 'CALL'
    window.Player = new YT.Player 'player',
      height: '631.8'
      width: '1036.8'
      videoId: ''
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
          .find '.playlist-date'
          .html item.date[0..9]
        $playtemplate
          .data 'video-id', item.id
        $playtemplate
          .attr 'data-video-id', item.id
        $playtemplate.on 'dblclick', (e) ->
          $this = $ this
          $video_id = $this.data 'video-id'
          console.log 'from double click ' + $video_id
          window.Playlist.play
            videoId: $video_id
            suggestedQuality: 'large'
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
      
      window.ShuffledPlaylist = _.shuffle window.Playlist.get()

    play: (item) ->
      console.log '>1 ', item
      
      $ '#playlist .bar-container'
        .addClass 'hide'
      $ "#playlist tr[data-video-id=#{item.videoId}]"
        .find '.bar-container'
        .removeClass 'hide'
      
      window.Player.loadVideoById item

      true

    # play: (item) ->
    #   console.error 'not implemented yet'
    #   window.Player.loadVideoById 
    #     id: item.id
    #     suggestedQuality: 'large'
    #   true

    removeById: (id) ->
      index = _.findIndex @list, (chr) ->
        return chr.id = id
      delete @list[index]
      @list = _.compact @list
      window.Playlist.render()
  
    shuffle: ->
      true


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
            date: item.snippet.publishedAt
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
      console.log suggestion
      window.Playlist.add suggestion
      window.Playlist.render()

