pool = require('../db/db').pool

module.exports.create = (id, password, callback) ->
  post = {user_id: id, user_password: password}
  pool.getConnection (err, conn) ->
    console.log err if err
    conn.query "INSERT INTO Users SET ?", post, (err, result) ->
      conn.release()
      return callback(err, result.insertId)

module.exports.findByNameAndPassword = (username, password, callback) ->
  pool.getConnection (err, conn) ->
    console.log err if err
    conn.query "
    SELECT *
    FROM Users
    WHERE user_id = ?
    AND user_password = ?
    "
    , [username, password], (err, results) ->
      conn.release()
      return callback(err, results[0])

module.exports.findById = (id, callback) ->
  pool.getConnection (err, conn) ->
    console.log err if err
    conn.query "
    SELECT *
    FROM Users
    WHERE id = ?
    "
    , [+id], (err, results) ->
      conn.release()
      return callback(err, results[0])

module.exports.findByName = (username, callback) ->
  pool.getConnection (err, conn) ->
    console.log err if err
    conn.query "
    SELECT *
    FROM Users
    WHERE user_id = ?
    "
    , [username], (err, results) ->
      conn.release()
      return callback(err, results[0])


module.exports.countByName = (username, callback) ->
  pool.getConnection (err, conn) ->
    console.log err if err
    conn.query "
    SELECT COUNT(id) as 'count'
    FROM Users
    WHERE user_id = ?
    ", [username], (err, results) ->
      conn.release()
      return callback(err, results[0].count)

module.exports.createSession = (req, user) ->
  delete user.user_password
  req.session.user = user
