express = require 'express'
app = express()
app.use express.static('public')
server = require('http').Server app
io = require('socket.io')(server)

THREE = require 'three'

SceneManager = require './SceneManager'

createBoxScene = () ->
    scene = new THREE.Scene()
    box = new THREE.Mesh(new THREE.BoxGeometry(1, 1, 1), new THREE.MeshBasicMaterial({ color: 0x888888 }))
    scene.add box
    box.userData.id = box.id
    scene

updateFn = () ->
    @scene.traverse (node) =>
        if node.type != "Scene"
            node.rotation.x += 0.001
            node.rotation.y += 0.001
            # for now, server can only change rotation and position
            @update
                id: node.id
                position:
                    x: node.position.x
                    y: node.position.y
                    z: node.position.z
                rotation:
                    x: node.rotation.x
                    y: node.rotation.y
                    z: node.rotation.z
                    order: node.rotation.order

scene = createBoxScene()

port = process.env.PORT || 3000
server.listen port

module.exports = new SceneManager app, io, scene, updateFn