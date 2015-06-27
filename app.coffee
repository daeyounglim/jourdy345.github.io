express = require 'express'
path = require 'path'
favicon = require 'serve-favicon'
logger = require 'morgan'
cookieParser = require 'cookie-parser'
bodyParser = require 'body-parser'
routes = require './routes/index'
users = require './routes/users'
sessions = require 'client-sessions'


app = express()

# view engine setup
app.set 'views', path.join __dirname, 'views'
app.set 'view engine', 'jade'

# uncomment after placing your favicon in /public
#app.use(favicon(__dirname + '/public/favicon.ico'))
app.use logger 'dev'
app.use bodyParser.json()
app.use bodyParser.urlencoded extended: false
app.use cookieParser()
app.use express.static path.join __dirname, 'public'

# Session set-up
app.use sessions 
  cookieName: 'ListifySession'
  requestKey: 'session'
  secret: 'a'
  duration: 24 * 60 * 60 * 1000
  activeDuration: 1000 * 60 * 5
  cookie:
    domain: '.lvh.me'
    # cannot be used with maxAge
    ephemeral: true
    httpOnly: true
    secure: false

app.use (req, res, next) ->
  res.locals.success = req.session.success
  res.locals.error = req.session.error
  res.locals.session = req.session or {}
  delete req.session.success
  delete req.session.error
  next()

app.use '/', routes
app.use '/users', users





# if process.env.NODE_ENV is 'production'
#   ...

# catch 404 and forward to error handler
app.use (req, res, next) -> 
  err = new Error 'Not Found'
  err.status = 404
  next err


# error handlers

# development error handler
# will print stacktrace
if app.get 'env'  is 'development'
  app.use (err, req, res, next) -> 
    res.status err.status or 500
    res.render 'error', 
      message: err.message,
      error: err

# production error handler
# no stacktraces leaked to user
app.use (err, req, res, next) -> 
  res.status err.status or 500
  res.render 'error', 
    message: err.message,
    error: {}


module.exports = app
