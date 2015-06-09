jQuery ->
  # window.Playlist = {}
  # Playlist._list = []
  # Playlist.getList =  ->
  #   return Playlist._list
  # Playlist.add = (item) ->
  #   Playlist._list.push item
  #   Playlist.render()
  #   true
  # Playlist.add_to_next = () ->
  #   Playlist._list.unshift item
  #   true
  # # Playlist.remove = (item) ->
  # #   true
  # Playlist.render = () ->
  #   # render
    
  #   true
  # Playlist.play = () ->
  #   true
  # Playlist.play_next = () ->
  #   true


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
      @render()

    add_to_next: (item) ->
      @list.unshift item

    render: ->

      for item in @list
        $playtemplate = $('.play-template').clone()
        $playtemplate
          .find '.title'
          .html item.title
        $playtemplate.removeClass 'play-template'
        $playtemplate.removeClass 'hide'
        $ '#playlist ul.playlist'
          .append $playtemplate
      console.log @list
      true

    play: ->
      true

  window.Playlist = new Playlist()


  $('[data-toggle~=youtube-search]')
    .on 'submit', ->
      $query = $ '#query'
      $.ajax 
        url: "https://www.googleapis.com/youtube/v3/search"
        type: "get"
        data: 
          q: $query.val()
          part: 'snippet'
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
              console.log 'Clicked ! ' + $this.data 'video-id'
              window.Playlist.add
                id: $this.data 'video-id'
                title: $this.data 'video-title'

            # remove class .hide
            $template.removeClass 'hide'
            $template.removeClass 'item-template'
            
            # append to UL
            $ul.append $template
            


            
            # .find('li.for-search').is(':not(.done)').append('<img src=#{item.snippet.thumbnails.default.url} />').addClass 'done'
          true

        error: (x, s, d) ->
          alert 'Error:' + s
      return false