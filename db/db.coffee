mysql = require 'mysql'

connection = mysql.createConnection
  host: process.env.DB_HOST
  user: process.env.DB_ID
  password: process.env.DB_PASSWORD
  database: 'Listify'


module.exports.connection = connection