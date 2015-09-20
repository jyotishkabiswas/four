Four = {}

class CardboardClient

    constructor: () ->

        @renderer = new THREE.WebGLRenderer() || new THREE.CanvasRenderer()
        @clientId = null
        @scene = new THREE.Scene()
        @camera = new THREE.PerspectiveCamera 75, window.innerWidth / window.innerHeight, 1, 10000
        @camera.position.z = 4
        @active = true
        @objects = {}
        @pin = -1
        @handAdapter = new HandAdapter @
        adapter

        loader = new THREE.ObjectLoader()

        @renderer.setSize window.innerWidth, window.innerHeight
        document.body.appendChild @renderer.domElement

        @io = io()
        @setCallbacks()

    setCallbacks: () ->

        @io.on 'connect', =>
            @io.emit 'cardboard', @pin

        @io.on 'message', (data) =>
            if data == 'error'
                @io.disconnect()
                $(".clientId").show()
            else # hand
                @handAdapter.frameAction JSON.parse(data)

        @io.on 'add', (object) =>
            loader.parse object, (obj3D) =>
                @scene.add obj3D
                @objects[object.object.userData.id] = obj3D

        @io.on 'remove', (id) =>
            toRemove = @objects[id]
            @scene.remove toRemove
            delete @objects[id]

        @io.on 'update', (object) =>
            old = @objects[object.id]
            unless old?
                @io.emit 'info', {id: object.id}
            else
                pos = object.position
                rot = object.rotation
                old.rotation.set rot.x, rot.y, rot.z, rot.order
                old.position.set pos.x, pos.y, pos.z

        @io.on 'object', (object) =>
            unless @objects[object.object.userData.id]?
                loader.parse object, (obj3D) =>
                    @objects[object.object.userData.id] = obj3D
                    @scene.add obj3D

        # handle 3D
        effect = new THREE.StereoEffect( renderer )
        effect.eyeSeparation = 10
        effect.setSize( window.innerWidth, window.innerHeight )

        sense = window.sense.init()
        sense.orientation (data) ->
            @camera.rotation.y = 90.0 - gamma
            @camera.rotation.x = beta
            @camera.rotation.z = alpha

        @animate()

    setPinAndConnect: ->
        @pin = $("input#pinInput").val()
        $(".clientId").hide()

    reconnect: ->
        @io = io()
        @setCallbacks()

    animate: ->
        requestAnimationFrame () =>
            @animate()
        @renderer.render @scene, @camera

Four.CardboardClient = CardboardClient