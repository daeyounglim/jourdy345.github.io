var OAUTH2_CLIENT_ID, OAUTH2_SCOPES, checkAuth, googleApiClientReady, loadAPIClientInterfaces;

OAUTH2_CLIENT_ID = '__YOUR_CLIENT_ID__';

OAUTH2_SCOPES = ['https://www.googleapis.com/auth/youtube'];

checkAuth = function() {
  gapi.auth.authorize({
    client_id: OAUTH2_CLIENT_ID,
    scope: OAUTH2_SCOPES,
    immediate: true
  }, handleAuthResult);
};

loadAPIClientInterfaces = function() {
  gapi.client.load('youtube', 'v3', function() {
    handleAPILoaded();
  });
};

googleApiClientReady = function() {
  gapi.auth.init(function() {
    window.setTimeout(checkAuth, 1);
  });
};

window.handleAuthResult = function(authResult) {
  if (authResult && !authResult.error) {
    $('.pre-auth').hide();
    $('.post-auth').show();
    loadAPIClientInterfaces();
  } else {
    $('#login-link').click(function() {
      gapi.auth.authorize({
        client_id: OAUTH2_CLIENT_ID,
        scope: OAUTH2_SCOPES,
        immediate: false
      }, handleAuthResult);
    });
  }
};
