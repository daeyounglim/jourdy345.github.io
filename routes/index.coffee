express = require 'express'
router = express.Router()
nodemailer = require 'nodemailer'

## GET home page.
router.get '/', (req, res, next) -> 
  res.render 'index', title: 'Express'

router.get '/iframe', (req, res) ->
  res.render 'iframe.jade'


router.post '/feedback', (req, res) ->
  transporter = nodemailer.createTransport
    service: 'iCloud'
    auth:
      user: 'jourdy345@me.com'
      pass: 'iamDY123!'

    mailOptions = 
      from: req.body.email
      to: "jourdy345@me.com"
      subject: req.body.title
      text: req.body.body

    transporter.sendMail mailOptions, (error, info) ->
      if error
        console.log error
        return res.redirect '/failure'
      console.log "Message sent: #{info.response}"
      res.redirect '/success'

router.get '/success', (req, res) ->
  res.send "We deeply appreciate your feedback."

router.get '/failure', (req, res) ->
  res.send "Message delivery failed"


module.exports = router


