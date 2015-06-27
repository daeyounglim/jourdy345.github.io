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

router.get('/logout', function(req, res) {
  req.session = {};
  return res.redirect('/');
});

router.post('/signin', function(req, res) {
  return connection.connect(function(err) {
    if (err) {
      console.log('error connection: ' + err.stack);
    }
    return connection.query("SELECT * FROM Users WHERE UserId = ? AND UserPassword = ?", [req.body.UserAccount, req.body.UserPassword], function(error, results, fields) {
      if (results) {
        req.session.user = results[0];
        console.log(results);
        connection.end();
        return res.redirect('/');
      } else {
        req.session.error = 'Whoops! No match found!';
        connection.end();
        return res.redirect('/');
      }
    });
  });
});

router.post('/signup', function(req, res) {
  var post;
  post = {
    UserId: req.body.UserAccount,
    UserPassword: req.body.UserPassword
  };
  return connection.connect(function(err) {
    if (err) {
      console.log('error connection: ' + err.stack);
    }
    return true;
    console.log('connected as id');
    return connection.query("SELECT * FROM Users WHERE UserId = ?", req.body.UserAccount, function(err, results) {
      if (err) {
        console.log(err);
      }
      console.log(results);
      if (!results) {
        return connection.query("INSERT INTO Users SET ?", post, function(error, results, fields) {
          console.log(error, results, fields);
          connection.end();
          return res.redirect('/');
        });
      } else {
        connection.end();
        req.session.error = 'Account name already exists! Please pick another one.';
        return res.redirect('/signup');
      }
    });
  });
});

module.exports = router;
