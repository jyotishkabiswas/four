THREE = require 'three'

class SceneManager

    constructor: (@io, scene = null, updateFn = null) ->
        @leapClients = {}
        @playerObjects = {}
        @cardboardClients = {}
        @scene = scene || new three.Scene()
        @io.on 'connection', initializeConnection


    initializeConnection: (socket) ->
        x = Math.floor(Math.random() * (9999 - 1000) + 1000)
        while x of clients
            x = Math.floor(Math.random() * (9999 - 1000) + 1000)

        socket.on 'disconnect', ->
            if socket of @leapClients
                cbSocket = @leapClients[socket]
                cbSocket.send 'error'
                delete @cardboardClients[cbSocket]
                delete @leapClients[socket]
            else

        socket.on 'message', (data) ->
            if data.match /leap/
                @leapClients[x] = socket
            else if data.match /cardboard (\d+)/
                code = parseInt data.split()[1]
                unless code of @leapClients
                    socket.send 'error'
                @cardboardClients[socket] = @leapClients[code]
                @leapClients

        socket.on 'hand', (leapHand) ->
            @playerObjects[socket].head[leapHand.type] = hand

        socket.on 'head', (data) ->
            @cardboardClients[socket].send data # send head position to correct client
            @playerObjects[socket].head.lookAt = data.lookAt
            @playerObjects[socket].head.up = data.up

    add: (object) ->
        @scene.add object
        @io.emit 'add', object

    remove: (object) ->
        @scene.remove object
        @io.emit 'remove', object

    update: (object) ->

    handleMessage: ->