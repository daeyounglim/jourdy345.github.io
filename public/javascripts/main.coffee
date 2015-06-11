jQuery ->

  player = undefined  ## Embed a player
  done = false

  onPlayerReady = (event) ->
    event.target.playVideo()
    return

  onPlayerStateChange = (event) ->
    if event.data is YT.PlayerState.PLAYING and !done
      setTimeout stopVideo, 1000
      done = true
    else if event.data is YT.PlayerState.ENDED
      console.log 'the video ended'
      player.loadVideoById 
        videoId: 'AnotherVideosID'
        suggestedQuality: 'large'
      player.playVideo()


  stopVideo = ->
    player.stopVideo()
    return

  window.onYouTubeIframeAPIReady = ->
    console.log 'CALL'
    player = new YT.Player 'player',
      height: '631.8'
      width: '1036.8'
      videoId: 'M7lc1UVf-VE'
      events:
        'onReady': onPlayerReady
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
      $playtemplate
        .find '.title'
        .html ''

      for item in @list
        $playtemplate = $('.play-template').clone()
        $playtemplate
          .find '.title'
          .html item.title
        $playtemplate
          .data 'video-id', item.id
        $playtemplate.removeClass 'play-template'
        $playtemplate.removeClass 'hide'
        $ '#playlist ul.playlist'
          .append $playtemplate
        console.log 'from render ' + @list
        true

    play: ->
      true

  window.Playlist = new Playlist()


  ## Use AJAX to send request to youtube search field and get the results / append to the jade file
  $('[data-toggle~=youtube-search]')
    .on 'submit', ->
      $query = $ '#query'
      $.ajax 
        url: "https://www.googleapis.com/youtube/v3/search"
        type: "get"
        data: 
          q: $query.val()
          part: 'snippet'
          maxResults: 50
          key: 'AIzaSyCImmWz0DcJdeD45YTwGB_ZmhNv167bwpM'
        success: (d, s, x) -> 
          # JSON.stringify d, null, '  '
          # result-->
          # {
          #   "kind": "youtube#searchListResponse",
          #   "etag": "\"dhbhlDw5j8dK10GxeV_UG6RSReM/tuMqs8zFxgEMOmznwzqkBMAZmrA\"",
          #   "nextPageToken": "CAUQAA",
          #   "pageInfo": {
          #     "totalResults": 1000000,
          #     "resultsPerPage": 5
          #   },
          #   "items": [
          #     {
          #       "kind": "youtube#searchResult",
          #       "etag": "\"dhbhlDw5j8dK10GxeV_UG6RSReM/zWa0nTjEfxvkByCmaOmcvZCcWQw\"",
          #       "id": {
          #         "kind": "youtube#video",
          #         "videoId": "O1KW3ZkLtuo"
          #       },
          #       "snippet": {
          #         "publishedAt": "2015-04-28T16:30:01.000Z",
          #         "channelId": "UCPDis9pjXuqyI7RYLJ-TTSA",
          #         "title": "Cats Being Jerks Video Compilation || FailArmy",
          #         "description": "For every cute internet cat, there's 5 more being assholes. Whether they're knocking shit over or attacking you for no reason, cats have proven that they are real ...",
          #         "thumbnails": {
          #           "default": {
          #             "url": "https://i.ytimg.com/vi/O1KW3ZkLtuo/default.jpg"
          #           },
          #           "medium": {
          #             "url": "https://i.ytimg.com/vi/O1KW3ZkLtuo/mqdefault.jpg"
          #           },
          #           "high": {
          #             "url": "https://i.ytimg.com/vi/O1KW3ZkLtuo/hqdefault.jpg"
          #           }
          #         },
          #         "channelTitle": "failarmy",
          #         "liveBroadcastContent": "none"
          #       }
          #     }
          #   ]
          # }
          $ul = $ '#search-container ul.collection'
          for item in d.items
            $template = $('.item-template').clone()
            console.log item.id.videoId, item.snippet.title, item.snippet.thumbnails.default.url
            # fill the template
            $template
              .find 'img'
              .attr 'src', item.snippet.thumbnails.default.url
            $template
              .find 'span.title'
              .html item.snippet.title or 'Untitled'
            $template
              .find 'p'
              .html item.snippet.description[0..10] + '...'
            $template
              .data 'video-id', item.id.videoId
            $template
              .data 'video-title', (item.snippet.title or 'Untitled')
            
            
            $template.on 'click', (e) ->
              $this = $ this
              
              video_list = {
                id: $this.data 'video-id'
                title: $this.data 'video-title'
              }
              console.log 'Clicked ! ' + video_list
              # Check if the clicked video is already in the Playlist
              unless window.Playlist.check video_list
              # Add to the Playlist if theres no match found
                console.log '>>>>>'
                window.Playlist.add
                  id: $this.data 'video-id'
                  title: $this.data 'video-title'
                window.Playlist.render()

            # remove class .hide
            $template.removeClass 'hide'
            $template.removeClass 'item-template'
            
            # append to UL
            $ul.append $template


          true

        error: (x, s, d) ->
          alert 'Error:' + s
      return false




