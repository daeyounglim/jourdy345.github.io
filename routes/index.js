var express, router;

express = require('express');

router = express.Router();

router.get('/', function(req, res, next) {
  return res.render('index', {
    title: 'Express'
  });
});

router.get('/iframe', function(req, res) {
  return res.render('iframe.jade');
});

module.exports = router;
