var connection, express, nodemailer, pool, router;

express = require('express');

router = express.Router();

nodemailer = require('nodemailer');

connection = require('../db/db').connection;

pool = require('../db/db').pool;

router.get('/', function(req, res, next) {
  return res.render('main.jade', {
    title: 'Express'
  });
});

router.get('/main/service', function(req, res) {
  return res.render('main_service.jade');
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

router.get('/playlist', function(req, res) {
  return pool.getConnection(function(err, conn) {
    if (err) {
      console.log(err);
    }
    return conn.query("SELECT * FROM Playlists WHERE user_id = ?", [req.session.user.user_id], function(error, results) {
      conn.release();
      if (error) {
        return console.log(error);
      }
      return res.status(200).json(results);
    });
  });
});

router.get('/playlist/:id/videos', function(req, res) {
  if (!isFinite(+req.params.id)) {
    res.status(200).json({
      status: 400,
      message: 'id(Number) invalid'
    });
    return;
  }
  return pool.getConnection(function(err, conn) {
    if (err) {
      console.log(err);
    }
    return conn.query("SELECT * FROM Videos WHERE playlist_id = ? AND user_id = ?", [+req.params.id, req.session.user.user_id], function(err, results) {
      conn.release();
      if (err) {
        return console.log(err);
      }
      console.log(results);
      return res.status(200).json(results);
    });
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

router.post('/signin', function(req, res) {
  return pool.getConnection(function(err, conn) {
    if (err) {
      console.log('error connection: ' + err.stack);
    }
    return conn.query("SELECT * FROM Users WHERE user_id = ? AND user_password = ?", [req.body.UserAccount, req.body.UserPassword], function(error, results, fields) {
      conn.release();
      if (results) {
        delete results[0].user_password;
        req.session.user = results[0];
        console.log(results);
        return res.redirect('/main/service');
      } else {
        req.session.error = 'Whoops! No match found!';
        return res.redirect('/main/service');
      }
    });
  });
});

router.post('/signup', function(req, res) {
  var post;
  post = {
    user_id: req.body.UserAccount,
    user_password: req.body.UserPassword
  };
  return pool.getConnection(function(err, conn) {
    if (err) {
      console.log('error connection: ' + err.stack);
    }
    return true;
    console.log('connected as id');
    return conn.query("SELECT * FROM Users WHERE user_id = ?", req.body.UserAccount, function(err, results) {
      if (err) {
        console.log(err);
      }
      console.log(results);
      if (!results) {
        return conn.query("INSERT INTO Users SET ?", post, function(error, results, fields) {
          console.log(error, results, fields);
          conn.release();
          return res.redirect('/');
        });
      } else {
        conn.release();
        req.session.error = 'Account name already exists! Please pick another one.';
        return res.redirect('/signup');
      }
    });
  });
});

router.post('/playlist/add/blank', function(req, res) {
  return pool.getConnection(function(err, conn) {
    var playlist;
    if (err) {
      console.log('error connection: ' + err.stack);
    }
    playlist = {
      user_id: req.session.user.user_id,
      playlist_name: req.body.blank_playlist_name
    };
    return conn.query("INSERT INTO Playlists SET ?", playlist, function(err, results) {
      if (err) {
        console.log(err);
      }
      console.log(results);
      return conn.query("SELECT * FROM Playlists WHERE user_id = ?", [req.session.user.user_id], function(error, results) {
        conn.release();
        if (error) {
          console.log(error);
        }
        console.log(results);
        if (req.accepts('application/json') && !req.accepts('html')) {
          return res.status(200).json(results);
        } else {
          return res.redirect('/main/service');
        }
      });
    });
  });
});

router.post('/playlist/add/new', function(req, res) {
  return pool.getConnection(function(err, conn) {
    var playlist;
    if (err) {
      console.log('error connection: ' + err.stack);
    }
    playlist = {
      user_id: req.session.user.user_id,
      playlist_name: req.body.playlist_name
    };
    return conn.query("INSERT INTO Playlists SET ?", [playlist], function(err, results) {
      conn.release();
      if (err) {
        console.log(err);
      }
      console.log(results);
      if (req.accepts('application/json') && !req.accepts('html')) {
        return res.status(200).json(results);
      }
    });
  });
});

router.post('/video/add', function(req, res) {
  var video_list;
  video_list = req.body.video_list || [];
  return pool.getConnection(function(err, conn) {
    var i, item, len, video;
    if (err) {
      console.log('error connection: ' + err.stack);
    }
    for (i = 0, len = video_list.length; i < len; i++) {
      video = video_list[i];
      item = {
        youtube_video_id: video.youtube_video_id,
        video_title: video.video_title,
        playlist_id: +req.body.playlist_id,
        user_id: req.session.user.user_id,
        play_count: video.play_count
      };
      conn.query("INSERT INTO Videos SET ?", item, function(err, results) {
        if (err) {
          console.log(err);
          res.status(200).json({
            status: 500,
            message: 'server error'
          });
        }
      });
    }
    res.status(200).json({
      status: 200,
      message: 'success'
    });
    return conn.release();
  });
});

router.post('/update/playcount/:id', function(req, res) {
  if (!isFinite(+req.params.id)) {
    res.status(200).json({
      status: 400,
      message: 'id(Number) invalid'
    });
    return;
  }
  return pool.getConnection(function(err, conn) {
    var video;
    video = JSON.parse(req.body.video);
    if (err) {
      console.log('error connection: ' + err.stack);
    }
    return conn.query("UPDATE Videos SET play_count = play_count + 1 WHERE user_id = ? AND playlist_id = ? AND id = ?", [req.session.user.user_id, +req.params.id, video.id], function(err, results) {
      conn.release();
      if (err) {
        console.log(err);
        return res.status(200).json({
          status: 500,
          message: 'server error'
        });
      }
      return res.status(200).json({
        status: 200,
        message: 'update success',
        content: results
      });
    });
  });
});

router.post('/delete/video/:id', function(req, res) {
  if (!isFinite(+req.params.id)) {
    res.status(200).json({
      status: 400,
      message: 'id(Number) invalid'
    });
    return;
  }
  return pool.getConnection(function(err, conn) {
    var video;
    video = JSON.parse(req.body.video);
    if (err) {
      console.log('error connection: ' + err.stack);
    }
    return conn.query("DELETE FROM Videos WHERE user_id = ? AND playlist_id = ? AND id = ?", [req.session.user.user_id, +req.params.id, +video.id], function(err, results) {
      conn.release();
      if (err) {
        return res.status(200).json({
          status: 500,
          message: 'server error'
        });
      }
      return res.status(200).json({
        status: 200,
        message: 'delete success',
        content: results
      });
    });
  });
});

module.exports = router;
