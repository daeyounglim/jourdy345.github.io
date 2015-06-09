# After the API loads, call a function to enable the search box.

handleAPILoaded = ->
  $ '#search-button'
    .attr 'disabled', false
  return

# Search for a specified string.

search = ->
  q = $('#query').val()
  request = gapi.client.youtube.search.list(
    q: q
    part: 'snippet')
  request.execute (response) ->
    str = JSON.stringify(response.result)
    $('#search-container').html '<pre>' + str + '</pre>'
    return
  return
