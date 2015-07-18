pool = require('../db/db').pool
db = require('../db/db')
Promise = require 'bluebird'

module.exports.create = (conn, options, callback) ->
  new Promise (resolve, reject) ->
    post = {user_id: options.id, user_password: options.password}
    conn.queryAsync "INSERT INTO Users SET ?", post
    .spread (row) ->
      resolve row.insertId

module.exports.findByNameAndPassword = (conn, username, password, callback) ->
  new Promise (resolve, reject) ->
    conn.query "
    SELECT *
    FROM Users
    WHERE user_id = ?
    AND user_password = ?
    ", [username, password]
    .spread (row) ->
      resolve row

module.exports.findById = (conn, id, callback) ->
  new Promise (resolve, reject) ->  
    conn.query "
    SELECT *
    FROM Users
    WHERE id = ?
    ", [+id]
    .spread (row) ->
      resolve row

module.exports.findByName = (conn, username, callback) ->
  new Promise (resolve, reject) ->  
    conn.query "
    SELECT *
    FROM Users
    WHERE user_id = ?
    ", [username]
    .spread (row) ->
      resolve row


module.exports.countByName = (conn, username, callback) -> 
  new Promise (resolve, reject) ->
    conn.query "
    SELECT COUNT(id) as 'count'
    FROM Users
    WHERE user_id = ?
    ", [username]
    .spread (row) ->
      resolve row.c

module.exports.createSession = (req, user) ->
  delete user.user_password
  req.session.user = user
