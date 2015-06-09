var done, onPlayerReady, onPlayerStateChange, player, stopVideo;

player = void 0;

done = false;

onPlayerReady = function(event) {
  event.target.playVideo();
};

onPlayerStateChange = function(event) {
  if (event.data === YT.PlayerState.PLAYING && !done) {
    setTimeout(stopVideo, 6000);
    done = true;
  }
};

stopVideo = function() {
  player.stopVideo();
};

window.onYouTubeIframeAPIReady = function() {
  console.log('CALL');
};
