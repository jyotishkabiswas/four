express = require 'express'
app = express()
app.use express.static('public')
server = require('http').Server app
io = require('socket.io')(server)

THREE = require 'three'

routes = require './routes/index'
SceneManager = require './SceneManager'

createBoxScene = () ->
    scene = new THREE.Scene()
    box = new THREE.Mesh(new THREE.BoxGeometry(1, 1, 1), new THREE.MeshBasicMaterial({ color: 0x888888 }))
    scene.add box
    scene

updateFn = () ->
    @scene.traverse (node) =>
        if node.type != "Scene"
            node.rotation.x += 0.01
            node.rotation.y += 0.01
            @update
                id: node.id
                rotation: node.rotation

scene = createBoxScene()

port = process.env.PORT || 3000
server.listen port

module.exports = new SceneManager app, io, scene, updateFn