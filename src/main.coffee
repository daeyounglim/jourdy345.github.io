jQuery ->
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
        if window.Player.getVideoData().video_id is window.Playlist.get()[window.Playlist.get().length - 1].id
          window.Playlist.play 0
        else
          currentVideoIndex =  _.findIndex window.Playlist.get(), (chr) ->
            return chr.id is window.Player.getVideoData().video_id
          window.Playlist.play currentVideoIndex + 1
      else if $('.playlist-button .repeat-one').hasClass 'button-active'
        currentVideoIndex =  _.findIndex window.Playlist.get(), (chr) ->
            return chr.id is window.Player.getVideoData().video_id
        window.Playlist.play currentVideoIndex
      else if $('.playlist-button .shuffle').hasClass 'button-active'
        currentVideoIndex =  _.findIndex window.ShuffledPlaylist, (chr) ->
          return chr.id is window.Player.getVideoData().video_id
        delete window.ShuffledPlaylist[currentVideoIndex]
        window.ShuffledPlaylist = _.compact window.ShuffledPlaylist
        if window.ShuffledPlaylist.length
          i = _.findIndex window.Playlist.get(), (chr) ->
            return chr.id is window.ShuffledPlaylist[0].id
          window.Playlist.play i
            # videoId: window.ShuffledPlaylist[0].id
            # suggestedQuality: 'large'
        else
          window.ShuffledPlaylist = _.shuffle window.Playlist.get()
          i = Math.floor(Math.random()*window.Playlist.get().length)
          window.Playlist.play i
            # videoId: window.Playlist.get()[i].id
            # suggestedQuality: 'large'
      else
        currentVideoIndex =  _.findIndex window.Playlist.get(), (chr) ->
          return chr.id is window.Player.getVideoData().video_id
        window.Playlist.play currentVideoIndex+1
          # videoId: window.Playlist.get()[currentVideoIndex + 1].id
          # suggestedQuality: 'large'


  stopVideo = ->
    window.Player.stopVideo()
    return

  window.onYouTubeIframeAPIReady = ->
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
      # unless @list
      #   @list = []
      
      @list = JSON.parse(localStorage.videos or '[]')
      @render() if @list.length
      # for video in videos
      #   @add video
    
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

    check: (item) ->
      for each in @list
        templist = JSON.stringify @list, null, '  '
        if templist.match item.id
          return true
        return false
      
    render: ->
      $playtemplate = $ '.play-template'
      $ '#playlist .item'
        .remove()

      for item in @list
        index = _.findIndex @list, (chr) ->
          return chr.id is item.id
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
        $playtemplate
          .attr 'data-video-id', item.id
        
        $playtemplate.removeClass 'play-template'
        $playtemplate.removeClass 'hide'
        $playtemplate.addClass 'item'
        $ '#playlist tbody'
          .append $playtemplate
      $ '#playlist .item'
        .on 'click', (e) ->
          $this = $ this
          $this.addClass 'active'
          $this.siblings().removeClass 'active'
        .on 'dblclick', (e) ->
          $this = $ this
          offset = $this.find('td:first').offset()
          height = $this.height()
          window.Playlist.play $this.attr 'id'
      
      window.ShuffledPlaylist = _.shuffle @get()

    play: (i) ->
      for item in @list
        item.playing = 0
      @list[i].playing = 1
      offset = $("#" + i).find('td:first').offset()
      height = $("#" + i).height()
      $ '.bar-container'
        .css
          'top': offset.top + 37 + height * 0.5
          'left': offset.left - 10
      window.Player.loadVideoById @list[i].id, 0, 'large'


    remove: (i) ->
      delete @list[i]
      @list = _.compact @list
      window.Playlist.render()
    # removeById: (id) ->
    #   index = _.findIndex @list, (chr) ->
    #     return chr.id = id
    #   delete @list[index]
    #   @list = _.compact @list
    #   window.Playlist.render()
  
    clear: ->
      @list = []

    remap: ->
      mapping = _.compact($("#sortable").sortable("toArray", {attribute: "id"}))
      tempPlaylist = []
      tempPlaylist[i] = @list[mapping[i]] for i in [0..(@list.length-1)]
      @list[i] = tempPlaylist[i] for i in [0..(@list.length-1)]
      window.Playlist.render()
      index = _.findIndex @list, (chr) ->
        return chr.id is window.Player.getVideoData().video_id
      offset = $('#'+index).find('td:first').offset()
      height = $('#'+index).height()
      $ '.bar-container'
        .css
          'top': offset.top + 37 + height * 0.5
          'left': offset.left - 10


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
    .on 'typeahead:selected', (e, suggestion, name) ->
      window.Playlist.add suggestion
      window.Playlist.render()

