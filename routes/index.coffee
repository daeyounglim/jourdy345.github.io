express = require 'express'
router = express.Router()

## GET home page.
router.get '/', (req, res, next) -> 
  res.render 'index', title: 'Express'

router.get '/iframe', (req, res) ->
  res.render 'iframe.jade'


module.exports = router


