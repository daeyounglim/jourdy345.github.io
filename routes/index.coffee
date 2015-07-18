express = require 'express'
router = express.Router()
nodemailer = require 'nodemailer'
db = require '../db/db'
Promise = require 'bluebird'
connection = require('../db/db').connection
pool = require('../db/db').pool
google = require 'googleapis'
request = require 'request'
moment = require 'moment'
GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET
FACEBOOK_APP_ID = process.env.FACEBOOK_APP_ID
FACEBOOK_APP_SECRET = process.env.FACEBOOK_APP_SECRET

models =
  user: require '../models/user'

#GET methods
## GET home page.
router.get '/', (req, res, next) ->
  res.render 'main.jade', title: 'Express'

router.get '/main/service', (req, res) ->
  res.render 'main_service.jade'

router.get '/user/:user_id', (req, res) ->
  user_id = req.params.user_id
  Promise.using db.getConnection(), (conn) ->
    conn.queryAsync "
    SELECT *
    FROM Playlists
    WHERE user_id = ?
    ", user_id
    .spread (rows) ->
      req.playlists = rows
    
      conn.queryAsync "
      SELECT *
      FROM Videos
      WHERE user_id = ?
      ", user_id
    .spread (rows) ->
      req.videos = rows
    .then ->
      playlists = req.playlists
      videos = req.videos
      rearrangedArray = []
      for playlist in playlists
        temp = []
        temp.push playlist
        temp2 = []
        for video, j in videos
          if +video.playlist_id == playlist.id
            temp2.push video
        temp.push temp2
        rearrangedArray.push temp
      req.rearrangedArray = rearrangedArray
    .then ->
      res.render 'user_page.jade',
        playlists: req.rearrangedArray
  .catch (err) ->
    console.log err

## Redirect success / failure
router.get '/feedback/success', (req, res) ->
  res.render 'feedback_success.jade'

router.get '/feedback/failure', (req, res) ->
  res.render 'feedback_failure.jade'

## GET signup page
router.get '/signup', (req, res) ->
  res.render 'signup.jade'

router.get '/logout', (req, res) ->
  req.session = {}
  return res.redirect '/'

## Sends user authentication request to Google / redirects the user to Google user-consent page
router.get '/login/google', (req, res) ->
  response_type = 'code'
  client_id = GOOGLE_CLIENT_ID
  redirect_uri = if process.env.NODE_ENV is 'production' then 'http://listify.tk/login/google/step2' else 'http://lvh.me:3000/login/google/step2'
  login_hint = 'email'
  scope = 'profile email'
  __QUERY__ = "?response_type=#{response_type}&client_id=#{client_id}&redirect_uri=#{redirect_uri}&login_hint=#{login_hint}&scope=#{scope}"
  url = 'https://accounts.google.com/o/oauth2/auth' + __QUERY__
  return res.redirect url

## Gets the authenticaton code from '/login/google' be it error or success / calls request for access token and refresh token
router.get '/login/google/step2', (req, res) ->
  code = req.query.code
  client_id = GOOGLE_CLIENT_ID
  client_secret = GOOGLE_CLIENT_SECRET
  redirect_uri = if process.env.NODE_ENV is 'production' then 'http://listify.tk/login/google/step2' else 'http://lvh.me:3000/login/google/step2'
  grant_type = 'authorization_code'
  __QUERY__ = "?code=#{code}&client_id=#{client_id}&client_secret=#{client_secret}&redirect_uri=#{redirect_uri}&grant_type=#{grant_type}"
  url = 'https://www.googleapis.com/oauth2/v3/token' + __QUERY__
  request.post url, (error, response, body) ->
    data = JSON.parse body
    if data.error
      return res.send data.error + ' ' + data.error_description
    request.get "https://www.googleapis.com/plus/v1/people/me?access_token=#{data.access_token}", (error, response, body) ->
      data = JSON.parse body
      console.log 'data: ' + JSON.stringify data, null, ' '
      if data.error
        return res.send data.error + ' ' + data.error_description

      pool.getConnection (err, conn) ->
        console.log('error connection: ' + err.stack) if err
        conn.query "
        SELECT COUNT(id) as `count`
        FROM Users
        WHERE user_id = ?
        "
        , [data.emails?[0].value], (err, results) ->
          console.log err if err
          post =
            user_id: data.emails[0].value
            user_password: ''
          req.session.img = data.image.url
          if results[0].count is 0
            # sign up
            conn.query "INSERT INTO Users SET ?", post, (error, results, fields) ->
              conn.release()
              delete post.user_password
              req.session.user = post
              return res.redirect '/main/service'
          else
            # login
            conn.release()
            delete post.user_password
            req.session.user = post
            return res.redirect '/main/service'


## Sends user authorization request to Facebook
router.get '/login/facebook', (req, res) ->
  client_id = FACEBOOK_APP_ID
  redirect_uri = if process.env.NODE_ENV is 'production' then 'http://listify.tk/login/facebook/step2' else 'http://lvh.me:3000/login/facebook/step2'
  response_type = 'code'
  scope = 'public_profile,email'
  __QUERY__ = "client_id=#{client_id}&redirect_uri=#{redirect_uri}&response_type=#{response_type}&scope=#{scope}"
  url = 'https://www.facebook.com/dialog/oauth?' + __QUERY__
  console.log url
  res.redirect url

router.get '/login/facebook/step2', (req, res) ->
  code = req.query.code
  client_id = FACEBOOK_APP_ID
  redirect_uri = if process.env.NODE_ENV is 'production' then 'http://listify.tk/login/facebook/step2' else 'http://lvh.me:3000/login/facebook/step2'
  client_secret = FACEBOOK_APP_SECRET
  __QUERY__ = "code=#{code}&client_id=#{client_id}&client_secret=#{client_secret}&redirect_uri=#{redirect_uri}"
  url = 'https://graph.facebook.com/v2.3/oauth/access_token?' + __QUERY__
  console.log url
  request.get url, (error, response, body) ->
    data = JSON.parse body
    access_token = data.access_token
    __QUERY__ = "access_token=#{access_token}"
    url = 'https://graph.facebook.com/me?' + __QUERY__
    request.get url, (error, response, body) ->
      data = JSON.parse body
      console.log data
      models.user.findByName data.name, (err, user) ->
        console.log err if err
        console.log 'user type: ', typeof user
        console.log 'user: ' + JSON.stringify user, null, ' '
        if not user
          models.user.create data.name, '', (err, result) ->
            console.log 'result: ' + result
            console.log err if err
            models.user.createSession req, {user_id: data.name}
            res.redirect '/main/service'
        else
          models.user.createSession req, user
          res.redirect '/main/service'



## GET Playlist
router.get '/playlist', (req, res) ->
  pool.getConnection (err, conn) ->
    console.log err if err
    conn.query "
    SELECT *
    FROM Playlists
    WHERE user_id = ?
    ", [req.session.user.user_id], (error, results) ->
      conn.release()
      return console.log error if error
      res
        .status 200
        .json results

## GET Videos
router.get '/playlist/:id/videos', (req, res) ->
  unless isFinite +req.params.id
    res
      .status 200
      .json
        status: 400
        message: 'id(Number) invalid'
    return
  pool.getConnection (err, conn) ->
    console.log err if err
    conn.query "
    SELECT *
    FROM Videos
    WHERE playlist_id = ?
      AND user_id = ?
    ", [+req.params.id, req.session.user.user_id], (err, results) ->
      conn.release()
      return console.log err if err
      console.log results
      res
        .status 200
        .json results


#POST methods
## POST gets feedback (nodemailer)
router.post '/feedback', (req, res) ->
  transporter = nodemailer.createTransport
    service: 'iCloud'
    auth:
      user: "jourdy345@me.com"
      pass: "iamDY123!"

  mailOptions =
    from: "jourdy345@me.com"
    to: "jourdy345@gmail.com"
    subject: "Feedback from Youtube Playlist"
    text: req.body.content

  transporter.sendMail mailOptions, (error, info) ->
    if error
      console.log error
      return res.redirect '/feedback/failure'
    console.log "Message sent: #{info.response}"
    res.redirect '/feedback/success'

## POST signin
router.post '/signin', (req, res) ->
  models.user.findByNameAndPassword req.body.UserAccount, req.body.UserPassword, (err, user) ->
    if user
      models.user.createSession req, user
      return res.redirect '/main/service'
    else
      req.session.error = 'Whoops! No match found!'
      return res.redirect '/main/service'
  # pool.getConnection (err, conn) ->
  #   console.log('error connection: ' + err.stack) if err
  #   conn.query "
  #   SELECT *
  #   FROM Users
  #   WHERE user_id = ?
  #     AND user_password = ?
  #   ", [req.body.UserAccount, req.body.UserPassword], (error, results, fields) ->
  #     conn.release()
  #     if results
  #       delete results[0].user_password
  #       req.session.user = results[0]
  #       console.log results
  #       return res.redirect '/main/service'
  #     else
  #       req.session.error = 'Whoops! No match found!'
  #       return res.redirect '/main/service'


## POST signup / stores User ID/PW
router.post '/signup', (req, res) ->
  post = {user_id: req.body.UserAccount, user_password: req.body.UserPassword}
  pool.getConnection (err, conn) ->
    console.log('error connection: ' + err.stack) if err
    return true
    console.log 'connected as id'

    conn.query "SELECT * FROM Users WHERE user_id = ?", req.body.UserAccount, (err, results) ->
      console.log err if err
      console.log results
      if not results
        conn.query "INSERT INTO Users SET ?", post, (error, results, fields) ->
          console.log error, results, fields
          conn.release()
          return res.redirect '/'
      else
        conn.release()
        req.session.error = 'Account name already exists! Please pick another one.'
        return res.redirect '/signup'

## POST adds a blank Playlist / responds to AJAX request
router.post '/playlist/add/blank', (req, res) ->
  pool.getConnection (err, conn) ->
    console.log('error connection: ' + err.stack) if err
    playlist =
      user_id: req.session.user.user_id
      playlist_name: req.body.blank_playlist_name

    conn.query "INSERT INTO Playlists SET ?", playlist, (err, results) ->
      console.log err if err
      console.log results
      conn.query "
      SELECT *
      FROM Playlists
      WHERE user_id = ?
      ", [req.session.user.user_id], (error, results) ->
        conn.release()
        console.log error if error
        console.log results
        if req.accepts('application/json') and not req.accepts('html')
          res
            .status 200
            .json results
        else
          res.redirect '/main/service'
## POST adds a playlist with videos / responds to AJAX request




router.post '/playlist/add/new', (req, res) ->
  Promise.using db.getConnection(), (conn) ->
    playlist =
      user_id: req.session.user.user_id
      playlist_name: req.body.playlist_name
    conn.queryAsync "INSERT INTO Playlists SET ?", playlist
    .spread (results) ->
      console.log 'results', results
      video_list = JSON.parse req.body.data
      console.log 'video_list: ', video_list
      video_list.forEach (e) ->
        item = {
          youtube_video_id: e.youtube_video_id
          video_title: e.video_title
          playlist_id: +results.insertId
          user_id: req.session.user.user_id
          play_count: e.play_count
          add_time: moment().valueOf()
        }
        console.log 'item: ', item
        conn.queryAsync "INSERT INTO Videos SET ?", item
        .then (results) ->
          console.log 'Videos insert: ', results
    .then ->
      res.json
        status: 200
        message: 'success'
  .catch (err) ->
    console.log err
  # pool.getConnection (err, conn) ->
  #   console.log('error connection: ' + err.stack) if err
  #   playlist =
  #     user_id: req.session.user.user_id
  #     playlist_name: req.body.playlist_name
  #   conn.query "INSERT INTO Playlists SET ?", playlist, (err, results) ->
  #     console.log err if err
  #     console.log results
  #     video_list = JSON.parse req.body.data
  #     console.log video_list
  #     video_list.forEach (e) ->
  #         youtube_video_id: e.youtube_video_id
  #         video_title: e.video_title
  #         playlist_id: +results.insertId
  #         user_id: req.session.user.user_id
  #         play_count: e.play_count
  #         add_time: moment().valueOf()
  #       console.log item
  #       conn.query "INSERT INTO Videos Set ?", item, (err, results) ->
  #         # if req.accepts('application/json') and not req.accepts('html')
  #         # res.json {results: results}
  #         console.log err if err
  #         console.log results
  #     res.json 
  #       data: results

## POST adds videos to 'Videos' table (works along with POST '/playlist/add/new') / responds to AJAX request
router.post '/video/add', (req, res) ->
  video_list = JSON.parse req.body.video_list
  Promise.using db.getConnection(), (conn) ->
    item =
      youtube_video_id: video_list.youtube_video_id
      video_title: video_list.video_title
      playlist_id: +req.body.playlist_id
      user_id: req.session.user.user_id
      play_count: video_list.play_count
      add_time: moment().valueOf()
    console.log 'item: ', item
    conn.queryAsync "INSERT INTO Videos SET ?", item
    .spread (result) ->
      console.log result.insertId
      res.json
        status: 200
        message: 'success!'
  .catch (err) ->
    console.log err

## POST updates play_count in Videos / responds to AJAX request (sends status & results but no rendering in the front)
router.post '/update/playcount/:id', (req, res) ->
  unless isFinite +req.params.id
    res
      .status 200
      .json
        status: 400
        message: 'id(Number) invalid'
    return
  pool.getConnection (err, conn) ->
    video = JSON.parse(req.body.video)
    console.log('error connection: ' + err.stack) if err
    conn.query "
    UPDATE Videos
       SET play_count = play_count + 1
     WHERE user_id = ?
       AND playlist_id = ?
       AND id = ?
    "
    , [req.session.user.user_id, +req.params.id, video.id], (err, results) ->
      conn.release()
      if err
        console.log err
        return res
          .status 200
          .json
            status: 500
            message: 'server error'
      res
        .status 200
        .json
          status: 200
          message: 'update success'
          content: results

## POST deletes video from Videos / responds to AJAX request
router.post '/video/delete/:id', (req, res) ->
  unless isFinite +req.params.id
    res
      .status 200
      .json
        status: 400
        message: 'id(Number) invalid'
    return
  pool.getConnection (err, conn) ->
    video = JSON.parse(req.body.video)
    console.log('error connection: ' + err.stack) if err
    conn.query "
    DELETE FROM Videos
          WHERE user_id = ?
            AND playlist_id = ?
            AND id = ?
    "
    , [req.session.user.user_id, +req.params.id, +video.id], (err, results) ->
      conn.release()
      if err
        return res
          .status 200
          .json
            status: 500
            message: 'server error'
      res
        .status 200
        .json
          status: 200
          message: 'video delete success'
          content: results

## POST deletes Playlist from Playlists / responds to AJAX request
router.post '/playlist/delete/:id', (req, res) ->
  unless isFinite req.params.id
    return res
      .status 200
      .json
        status: 400
        message: 'id(Number) invalid'
  pool.getConnection (err, conn) ->
    console.log err if err
    conn.query "
    DELETE FROM Playlists
          WHERE user_id = ?
            AND id = ?
    "
    , [req.session.user.user_id, +req.params.id], (err, results) ->
      conn.query "
      DELETE FROM Videos
            WHERE user_id = ?
              AND playlist_id = ?
      "
      , [req.session.user.user_id, +req.params.id], (err, results) ->
        conn.release()
        if err
          return res
            .status 200
            .json
              status: 500
              message: 'server error'

        res
          .status 200
          .json
            status: 200
            message: 'playlist delete success'
module.exports = router
