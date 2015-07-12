var FACEBOOK_APP_ID, FACEBOOK_APP_SECRET, GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, connection, express, google, models, nodemailer, pool, request, router;

express = require('express');

router = express.Router();

nodemailer = require('nodemailer');

connection = require('../db/db').connection;

pool = require('../db/db').pool;

google = require('googleapis');

request = require('request');

GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID;

GOOGLE_CLIENT_SECRET = process.env.GOOGLE_CLIENT_SECRET;

FACEBOOK_APP_ID = process.env.FACEBOOK_APP_ID;

FACEBOOK_APP_SECRET = process.env.FACEBOOK_APP_SECRET;

models = {
  user: require('../models/user')
};

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

router.get('/login/google', function(req, res) {
  var __QUERY__, client_id, login_hint, redirect_uri, response_type, scope, url;
  response_type = 'code';
  client_id = GOOGLE_CLIENT_ID;
  redirect_uri = 'http://lvh.me:3000/login/google/step2';
  login_hint = 'email';
  scope = 'profile email';
  __QUERY__ = "?response_type=" + response_type + "&client_id=" + client_id + "&redirect_uri=" + redirect_uri + "&login_hint=" + login_hint + "&scope=" + scope;
  url = 'https://accounts.google.com/o/oauth2/auth' + __QUERY__;
  return res.redirect(url);
});

router.get('/login/google/step2', function(req, res) {
  var __QUERY__, client_id, client_secret, code, grant_type, redirect_uri, url;
  code = req.query.code;
  client_id = GOOGLE_CLIENT_ID;
  client_secret = GOOGLE_CLIENT_SECRET;
  redirect_uri = 'http://lvh.me:3000/login/google/step2';
  grant_type = 'authorization_code';
  __QUERY__ = "?code=" + code + "&client_id=" + client_id + "&client_secret=" + client_secret + "&redirect_uri=" + redirect_uri + "&grant_type=" + grant_type;
  url = 'https://www.googleapis.com/oauth2/v3/token' + __QUERY__;
  return request.post(url, function(error, response, body) {
    var data;
    data = JSON.parse(body);
    if (data.error) {
      return res.send(data.error + ' ' + data.error_description);
    }
    return request.get("https://www.googleapis.com/plus/v1/people/me?access_token=" + data.access_token, function(error, response, body) {
      data = JSON.parse(body);
      console.log('data: ' + data);
      if (data.error) {
        return res.send(data.error + ' ' + data.error_description);
      }
      return pool.getConnection(function(err, conn) {
        var ref;
        if (err) {
          console.log('error connection: ' + err.stack);
        }
        return conn.query("SELECT COUNT(id) as `count` FROM Users WHERE user_id = ?", [(ref = data.emails) != null ? ref[0].value : void 0], function(err, results) {
          var post;
          if (err) {
            console.log(err);
          }
          post = {
            user_id: data.emails[0].value,
            user_password: ''
          };
          if (results[0].count === 0) {
            return conn.query("INSERT INTO Users SET ?", post, function(error, results, fields) {
              conn.release();
              delete post.user_password;
              req.session.user = post;
              return res.redirect('/main/service');
            });
          } else {
            conn.release();
            delete post.user_password;
            req.session.user = post;
            return res.redirect('/main/service');
          }
        });
      });
    });
  });
});

router.get('/login/facebook', function(req, res) {
  var __QUERY__, client_id, redirect_uri, response_type, scope, url;
  client_id = FACEBOOK_APP_ID;
  redirect_uri = 'http://lvh.me:3000/login/facebook/step2';
  response_type = 'code';
  scope = 'email';
  __QUERY__ = "client_id=" + client_id + "&redirect_uri=" + redirect_uri + "&response_type=" + response_type + "&scope=" + scope;
  url = 'https://www.facebook.com/dialog/oauth?' + __QUERY__;
  console.log(url);
  return res.redirect(url);
});

router.get('/login/facebook/step2', function(req, res) {
  var __QUERY__, client_id, client_secret, code, redirect_uri, url;
  code = req.query.code;
  client_id = FACEBOOK_APP_ID;
  redirect_uri = 'http://lvh.me:3000/login/facebook/step2';
  client_secret = FACEBOOK_APP_SECRET;
  __QUERY__ = "code=" + code + "&client_id=" + client_id + "&client_secret=" + client_secret + "&redirect_uri=" + redirect_uri;
  url = 'https://graph.facebook.com/v2.3/oauth/access_token?' + __QUERY__;
  console.log(url);
  return request.get(url, function(error, response, body) {
    var access_token, data;
    data = JSON.parse(body);
    access_token = data.access_token;
    __QUERY__ = "access_token=" + access_token;
    url = 'https://graph.facebook.com/me?' + __QUERY__;
    return request.get(url, function(error, response, body) {
      data = JSON.parse(body);
      return models.user.findByName(data.name, function(err, user) {
        if (err) {
          console.log(err);
        }
        console.log('user: ' + user);
        if (!user) {
          return models.user.create(data.name, '', function(err, result) {
            console.log('result: ' + result);
            if (err) {
              console.log(err);
            }
            models.user.createSession(req, user);
            return res.redirect('/main/service');
          });
        } else {
          models.user.createSession(req, user);
          return res.redirect('/main/service');
        }
      });
    });
  });
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
  return models.user.findByNameAndPassword(req.body.UserAccount, req.body.UserPassword, function(err, user) {
    if (user) {
      models.user.createSession(req, user);
      return res.redirect('/main/service');
    } else {
      req.session.error = 'Whoops! No match found!';
      return res.redirect('/main/service');
    }
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
  video_list = JSON.parse(req.body.video_list) || [];
  console.log(video_list);
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

router.post('/video/delete/:id', function(req, res) {
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
        message: 'video delete success',
        content: results
      });
    });
  });
});

router.post('/playlist/delete/:id', function(req, res) {
  if (!isFinite(req.params.id)) {
    return res.status(200).json({
      status: 400,
      message: 'id(Number) invalid'
    });
  }
  return pool.getConnection(function(err, conn) {
    if (err) {
      console.log(err);
    }
    return conn.query("DELETE FROM Playlists WHERE user_id = ? AND id = ?", [req.session.user.user_id, +req.params.id], function(err, results) {
      return conn.query("DELETE FROM Videos WHERE user_id = ? AND playlist_id = ?", [req.session.user.user_id, +req.params.id], function(err, results) {
        conn.release();
        if (err) {
          return res.status(200).json({
            status: 500,
            message: 'server error'
          });
        }
        return res.status(200).json({
          status: 200,
          message: 'playlist delete success'
        });
      });
    });
  });
});

module.exports = router;
