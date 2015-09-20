app = require('express')()
server = require('http').Server app
io = require('socket.io')(server)

app.use

three = require 'three'

routes = require './routes/index'

port = process.env.PORT || 3000
server.listen port

scene = new Three.Scene()

module.exports = new SceneManager io, scene