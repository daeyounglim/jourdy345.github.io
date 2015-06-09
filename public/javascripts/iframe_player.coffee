player = undefined
# 5. The API calls this function when the player's state changes.
#    The function indicates that when playing a video (state=1),
#    the player should play for six seconds and then stop.
done = false

onPlayerReady = (event) ->
  event.target.playVideo()
  return

onPlayerStateChange = (event) ->
  if event.data is YT.PlayerState.PLAYING and !done
    setTimeout stopVideo, 6000
    done = true
  return

stopVideo = ->
  player.stopVideo()
  return

window.onYouTubeIframeAPIReady = ->
  console.log 'CALL'
  # player = new YT.Player 'player',
  #   height: '702'
  #   width: '1152'
  #   videoId: 'M7lc1UVf-VE'
  #   events:
  #     'onReady': onPlayerReady
  #     'onStateChange': onPlayerStateChange
  return

# player.loadVideoById 
#   'videoID': 'String'
#   'startSeconds': 5
#   'endSeconds': 60
#   'suggestedQuality': 'large'

# player.cueVideoById 
#   videoID: String
#   startSeconds: Number
#   endSeconds: Number
#   suggestedQuality: String
