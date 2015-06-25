express = require 'express'
router = express.Router()
nodemailer = require 'nodemailer'
connection = require('../db/db').connection

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
  post = {UserId: req.body.UserAccount, UserPassword: req.body.UserPassword}
  connection.connect (err) ->
    console.log('error connection: ' + err.stack) if err
    return true
    console.log 'connected as id'
  connection.query 'INSERT INTO Users SET ?', post, (error, results, fields) ->
    console.log error, results, fields
  connection.end()
  res.redirect '/'




module.exports = router


