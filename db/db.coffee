mysql = require 'mysql'

module.exports.connection = connection = mysql.createConnection
  host: process.env.DB_HOST
  user: process.env.DB_ID
  password: process.env.DB_PASSWORD
  database: 'Listify'


module.exports.pool = pool = mysql.createPool
  connectionLimit: 20
  host: process.env.DB_HOST
  user: process.env.DB_ID
  password: process.env.DB_PASSWORD
  database: 'Listify'


module.exports.getConnection = getConnection = ->
  pool.getConnectionAsync().disposer (db, promise) ->
    db.release()