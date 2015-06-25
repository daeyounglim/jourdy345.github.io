express = require 'express'
router = express.Router()
nodemailer = require 'nodemailer'
Mariasql = require 'mariasql'
connection = new Mariasql()
connection.connect
  host: 'localhost'
  user: 'root'
  password: '024160'
  db: 'IDPW'


module.exports = connection

## GET home page.
router.get '/', (req, res, next) -> 
  res.render 'index.jade', title: 'Express'

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

## Redirect success / failure
router.get '/feedback/success', (req, res) ->
  res.render 'feedback_success.jade'

router.get '/feedback/failure', (req, res) ->
  res.render 'feedback_failure.jade'


## GET signup page
router.get '/signup', (req, res) ->
  res.render 'signup.jade'

## POST signup / STORE User ID/PW
router.post '/signup', (req, res) ->
  console.log req.body.UserAccount, req.body.UserPassword
  query = connection.query 'INSERT INTO Id_Password SET id = #{req.body.UserAccount}, password = #{req.body.UserPassword};'
  query.on 'result', (result) ->
    console.log result
  query.on 'error', (err) ->
    console.log err
  query.on 'fields', (fields) ->
    console.log fields
  connection.end()
  res.redirect '/'
module.exports = router


