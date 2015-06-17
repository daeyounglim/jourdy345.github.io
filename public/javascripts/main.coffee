jQuery ->

  window.Player = undefined
  done = false
  $(document)
    .on 'keydown', (e) ->
      $active = $ '#playlist .item.active'
      unless $('.form-control').is(':focus')
        if $active.length
          if e.keyCode is 8 or 46
            $ '.forBackspace'
              .focus()
            $this = $active.first()
            console.error '???'
            window.Playlist.removeById($this.data 'video-id')
            console.log $this.data 'video-id'
            e.preventDefault()
            e.stopPropagation()
            if $this.data 'video-id' is window.Player.getVideoData().video_id
              $ '.bar-container'
                .css
                  'top': -9999
                  'left': -9999
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
          window.Playlist.play 0
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
        'controls': 1
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
        index = _.findIndex @list, (chr) ->
          return chr.id is item.id
        console.log index
        $playtemplate = $('#playlist .play-template').clone()
        $playtemplate
          .find '.playlist-title'
          .html item.title
        $playtemplate
          .find '.playlist-date'
          .html item.date
        $playtemplate
          .data 'video-id', item.id
        $playtemplate
          .attr 'id', index
        $playtemplate.removeClass 'play-template'
        $playtemplate.removeClass 'hide'
        $playtemplate.addClass 'item'
        $ '#playlist tbody'
          .append $playtemplate
      
        console.log 'from render ' + @list
        console.log $playtemplate.data 'video-id'

      $ '#playlist .item'
        .on 'click', (e) ->
          $this = $ this
          $this.addClass 'active'
          $this.siblings().removeClass 'active'
        .on 'dblclick', (e) ->
          $this = $ this
          offset = $this.find('td:first').offset()
          height = $this.height()
          $ '.bar-container'
            .css
              'top': offset.top + 37 + height * 0.5 
              'left': offset.left - 10
          window.Playlist.play
            videoId: $this.data 'video-id'
            suggestedQuality: 'large'
      
      window.ShuffledPlaylist = _.shuffle window.Playlist.get()

    play: (i) ->
      window.Player.loadVideoById @list[i].id, 0, 'large'
      for item in @list
        item.playing = 0
      @list[i].playing = 1
      offset = $("##{i}]").find('td:first').offset()
      height = $("##{i}]").height
      $ '.bar-container'
        .css
          'top': offset.top + 37 + height * 0.5
          'left': offset.left - 10

    removeById: (id) ->
      index = _.findIndex @list, (chr) ->
        return chr.id = id
      delete @list[index]
      @list = _.compact @list
      window.Playlist.render()
  
    shuffle: ->
      true

    remap: ->
      mapping = $("#sortable").sortable("toArray",{attribute: "id"})
      tempVideos = []
      tempVideos[i] = @list[mapping[i]] for i in [0..(@list.length-1)]
      @list[i] = tempVideos[i] for i in [0..(@list.length-1)]
      render()

  window.Playlist = new Playlist()
  window.Playlist.add 
    title: "California Drought Is God’s Punishment For Abortion Laws"
    id: "Kn8_wCGd80g"
    imgUrl: "https://i.ytimg.com/vi/Kn8_wCGd80g/default.jpg"
    date: "2015-06-16"
  window.Playlist.add
    title: "OMFG - Hello"
    id: "ih2xubMaZWI"
    imgUrl: "https://i.ytimg.com/vi/ih2xubMaZWI/default.jpg"
    date: "2014-12-25"
  

  window.Playlist.render()

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
            date: item.snippet.publishedAt[0..9]
            playing: 0
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
        suggestion: Handlebars.compile '<img src="{{imgUrl}}" /><p><strong>{{title}} | {{date}}<strong></p>'
        # suggestion: (data) ->
        #   console.log '>>', data
        #   return Handlebars.compile '<p><strong>{{title}} - {{id}}<strong></p>', data
        # # suggestion: Handlebars.compile '<p><strong>{{title}} - {{id}}<strong></p>'
    .on 'typeahead:selected', (e, suggestion, name) ->
      console.log suggestion
      window.Playlist.add suggestion
      window.Playlist.render()

