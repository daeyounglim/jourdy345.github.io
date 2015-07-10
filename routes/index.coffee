express = require 'express'
router = express.Router()
nodemailer = require 'nodemailer'
connection = require('../db/db').connection
pool = require('../db/db').pool

#GET methods
## GET home page.
router.get '/', (req, res, next) ->
  res.render 'main.jade', title: 'Express'

router.get '/main/service', (req, res) ->
  res.render 'main_service.jade'

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
  pool.getConnection (err, conn) ->
    console.log('error connection: ' + err.stack) if err
    conn.query "
    SELECT *
    FROM Users
    WHERE user_id = ?
      AND user_password = ?
    ", [req.body.UserAccount, req.body.UserPassword], (error, results, fields) ->
      conn.release()
      if results
        delete results[0].user_password
        req.session.user = results[0]
        console.log results
        return res.redirect '/main/service'
      else
        req.session.error = 'Whoops! No match found!'
        return res.redirect '/main/service'


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
  pool.getConnection (err, conn) ->
    console.log('error connection: ' + err.stack) if err
    playlist =
      user_id: req.session.user.user_id
      playlist_name: req.body.playlist_name
    conn.query "INSERT INTO Playlists SET ?", [playlist], (err, results) ->
      conn.release()
      console.log err if err
      console.log results
      if req.accepts('application/json') and not req.accepts('html')
        return res
          .status 200
          .json results

## POST adds videos to 'Videos' table (works along with POST '/playlist/add/new') / responds to AJAX request
router.post '/video/add', (req, res) ->
  video_list = req.body.video_list or []
  pool.getConnection (err, conn) ->
    console.log('error connection: ' + err.stack) if err
    for video in video_list
      item =
        youtube_video_id: video.youtube_video_id
        video_title: video.video_title
        playlist_id: +req.body.playlist_id
        user_id: req.session.user.user_id
        play_count: video.play_count
      conn.query "INSERT INTO Videos SET ?", item, (err, results) ->
        if err
          console.log err
          res
            .status 200
            .json
              status: 500
              message: 'server error'
          return
    res
      .status 200
      .json
        status: 200
        message: 'success'
    conn.release()

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
