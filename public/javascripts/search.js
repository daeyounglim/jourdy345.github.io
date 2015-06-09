var handleAPILoaded, search;

handleAPILoaded = function() {
  $('#search-button').attr('disabled', false);
};

search = function() {
  var q, request;
  q = $('#query').val();
  request = gapi.client.youtube.search.list({
    q: q,
    part: 'snippet'
  });
  request.execute(function(response) {
    var str;
    str = JSON.stringify(response.result);
    $('#search-container').html('<pre>' + str + '</pre>');
  });
};
