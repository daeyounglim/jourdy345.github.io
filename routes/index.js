var express, nodemailer, router;

express = require('express');

router = express.Router();

nodemailer = require('nodemailer');

router.get('/', function(req, res, next) {
  return res.render('index', {
    title: 'Express'
  });
});

router.get('/iframe', function(req, res) {
  return res.render('iframe.jade');
});

router.post('/feedback', function(req, res) {
  var mailOptions, transporter;
  return transporter = nodemailer.createTransport({
    service: 'iCloud',
    auth: {
      user: 'jourdy345@me.com',
      pass: 'iamDY123!'
    }
  }, mailOptions = {
    from: req.body.email,
    to: "jourdy345@me.com",
    subject: req.body.title,
    text: req.body.body
  }, transporter.sendMail(mailOptions, function(error, info) {
    if (error) {
      console.log(error);
      return res.redirect('/failure');
    }
    console.log("Message sent: " + info.response);
    return res.redirect('/success');
  }));
});

router.get('/success', function(req, res) {
  return res.send("We deeply appreciate your feedback.");
});

router.get('/failure', function(req, res) {
  return res.send("Message delivery failed");
});

module.exports = router;
