express = require 'express'
app = express()
app.use express.static('public')
server = require('http').Server app
io = require('socket.io')(server)

THREE = require 'three'

SceneManager = require './SceneManager'

class Puck

    constructor: (@r = 1.0) ->
        @geo = new THREE.CylinderGeometry r, r, 0.1, 32
        @mat = new THREE.MeshPhongMaterial {color:'0x111111'}
        @cylinder = new THREE.Mesh( geo, mat )
        @velocity = new THREE.Vector3()


class Peg

    constructor: (@r, @c) ->
        @geob = new THREE.CylinderGeometry r, r, 0.5, 32
        @geot = new THREE.CylinderGeometry r/0.7, r/0.7, 0.5, 32
        @mat = new THREE.MeshPhongMaterial {color: c}
        @cylinders = [new THREE.Mesh(geob, mat), new THREE.Mesh(geot, mat)]
        @velocity = new THREE.Vector3
        @mass = 1

class Table

    constructor: (@w, @d, @puckr, @pegr, @scene) ->
        @puck = new Puck()
        @scene.add @puck.cylinder
        @pegs = [new Peg(1.5, '0x110000'), new Peg(0.5, '0x000011')]
        for peg in pegs
            for cylinder in peg.cylinders
                @scene.add @puck.cylinder
        x, y = math.random(), math.random()
        @puck.velocity = (0.2 * (new THREE.Vector3 x, 0.0, z)) / 60.0
        @m_s = 0.1
        @m_d = 0.01
        @mass = 1.3

    update: () ->
        newPos = @puck.cylinder.position + @puck.velocity

        for peg in @pegs
            c = peg.cylinders[0].position
            if peg.cylinders[0].distanceTo @puck.cylinder.position < peg.r + @puck.r
                ppeg = peg.velocity * peg.mass
                ppuck = puck.velocity * puck.mass
                ppuck += ppeg.dot(@puck)



        if newPos.x > @w/2

        else if newPos.x < -@w/2

        else if newPos.z > @d/2

        else if newPos.z < -@d/2

        if @puck.velocity > 0.0001
            @puck.velocity *= (1- 0.01 * @puck.velocity)




class Peg

    constructor: (radius) ->

createAirHockeyScene = () ->
    scene = new THREE.Scene()
    sm = new SceneManager app, io, scene, updateFn
    # table = new THREE.Mesh(new THREE.BoxGeometry(10, 15, 1), new THREE.MeshPhongMaterial({ color: 0x888888 }))
    scene.add table
    box.userData.id = box.id
    scene

updateFn = () ->

scene = createBoxScene()

port = process.env.PORT || 3000
server.listen port

module.exports = new SceneManager app, io, scene, updateFn