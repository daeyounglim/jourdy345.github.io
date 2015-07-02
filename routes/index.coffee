express = require 'express'
router = express.Router()
nodemailer = require 'nodemailer'
connection = require('../db/db').connection
pool = require('../db/db').pool

#GET methods
## GET home page.
router.get '/', (req, res, next) ->
  res.render 'index.jade', title: 'Express'

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
## POST feedback (nodemailer)
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
  connection.connect (err) ->
    console.log('error connection: ' + err.stack) if err
    connection.query "
    SELECT * 
    FROM Users
    WHERE user_id = ?
      AND user_password = ?
    ", [req.body.UserAccount, req.body.UserPassword], (error, results, fields) ->
      if results
        req.session.user = results[0]
        console.log results
        connection.end()
        return res.redirect '/'
      else
        req.session.error = 'Whoops! No match found!'
        connection.end()
        return res.redirect '/'


## POST signup / STORE User ID/PW
router.post '/signup', (req, res) ->
  post = {user_id: req.body.UserAccount, user_password: req.body.UserPassword}
  connection.connect (err) ->
    console.log('error connection: ' + err.stack) if err
    return true
    console.log 'connected as id'

    connection.query "SELECT * FROM Users WHERE user_id = ?", req.body.UserAccount, (err, results) ->
      console.log err if err
      console.log results
      if not results
        connection.query "INSERT INTO Users SET ?", post, (error, results, fields) ->
          console.log error, results, fields
          connection.end()
          return res.redirect '/'
      else
        connection.end()
        req.session.error = 'Account name already exists! Please pick another one.'
        return res.redirect '/signup'

## POST add, store Playlist / respond to AJAX request
router.post '/playlist/add', (req, res) ->
  pool.getConnection (err, conn) ->
    console.log('error connection: ' + err.stack) if err
    items = JSON.parse(req.body.video_list)
    playlist =
      user_id: req.session.user.user_id
      playlist_name: req.body.playlist_name

    conn.query "INSERT INTO Playlists SET ?", playlist, (err, results) ->
      console.log err if err
      console.log results
      for item in items
        post = 
          playlist_id: results.insertId
          youtube_video_id: item.id
          user_id: req.session.user.user_id
          video_title: item.title
        conn.query "INSERT INTO Videos SET ?", post, (err, results) ->
          console.log err if err
          console.log results
      conn.release()
      if req.accepts('application/json') and not req.accepts('html')
        res.json(results)
      else
        res.redirect('/')

# router.post '/video/add', (req, res) ->
#   items = JSON.parse(req.body.video_list)
#   videos =
#     playlist_id: 
#     youtube_video_id:
#     comment_count:
#     user_id:
#   pool.getConnection (err, conn) ->
#     console.log('error connection: ' + err.stack) if err
#     # item = [{"title":"윤하 (Younha) - 없어 (Not There) (feat. Eluphant)","id":"LRGJcX27qTA","imgUrl":"https://i.ytimg.com/vi/LRGJcX27qTA/default.jpg","date":"2013-12-06","playing":0}]
#     for item in items
#       post = 
#         playlist_id: 
#         youtube_video_id: item.id
#         video_title: item.title
#         user_id: req.session.user.user_id
#       conn.query "
#       INSERT INTO Videos
#       SET ?
#       "



module.exports = router


