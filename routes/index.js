var connection, express, nodemailer, router;

express = require('express');

router = express.Router();

nodemailer = require('nodemailer');

connection = require('../db/db').connection;

router.get('/', function(req, res, next) {
  return res.render('index.jade', {
    title: 'Express'
  });
});

router.post('/feedback', function(req, res) {
  var mailOptions, transporter;
  transporter = nodemailer.createTransport({
    service: 'iCloud',
    auth: {
      user: "jourdy345@me.com",
      pass: "iamDY123!"
    }
  });
  mailOptions = {
    from: "jourdy345@me.com",
    to: "jourdy345@gmail.com",
    subject: "Feedback from Youtube Playlist",
    text: req.body.content
  };
  return transporter.sendMail(mailOptions, function(error, info) {
    if (error) {
      console.log(error);
      return res.redirect('/feedback/failure');
    }
    console.log("Message sent: " + info.response);
    return res.redirect('/feedback/success');
  });
});

router.get('/feedback/success', function(req, res) {
  return res.render('feedback_success.jade');
});

router.get('/feedback/failure', function(req, res) {
  return res.render('feedback_failure.jade');
});

router.get('/signup', function(req, res) {
  return res.render('signup.jade');
});

router.post('/signup', function(req, res) {
  var post;
  post = {
    UserId: req.body.UserAccount,
    UserPassword: req.body.UserPassword
  };
  connection.connect(function(err) {
    if (err) {
      console.log('error connection: ' + err.stack);
    }
    return true;
    return console.log('connected as id');
  });
  connection.query('INSERT INTO Users SET ?', post, function(error, results, fields) {
    return console.log(error, results, fields);
  });
  connection.end();
  return res.redirect('/');
});

module.exports = router;
