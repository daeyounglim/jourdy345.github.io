var Mariasql, connection, express, nodemailer, router;

express = require('express');

router = express.Router();

nodemailer = require('nodemailer');

Mariasql = require('mariasql');

connection = new Mariasql();

connection.connect({
  host: 'localhost',
  user: 'root',
  password: '024160',
  db: 'IDPW'
});

module.exports = connection;

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
  var query;
  console.log(req.body.UserAccount, req.body.UserPassword);
  query = connection.query('INSERT INTO Id_Password SET id = #{req.body.UserAccount}, password = #{req.body.UserPassword};');
  query.on('result', function(result) {
    return console.log(result);
  });
  query.on('error', function(err) {
    return console.log(err);
  });
  query.on('fields', function(fields) {
    return console.log(fields);
  });
  connection.end();
  return res.redirect('/');
});

module.exports = router;
