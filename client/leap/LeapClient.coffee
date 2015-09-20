Four = {}

class LeapClient

    constructor: (@url) ->

        @renderer = new THREE.WebGLRenderer() || new THREE.CanvasRenderer()
        @clientId = null
        @scene = new THREE.Scene()
        @camera = new THREE.PerspectiveCamera 75, window.innerWidth / window.innerHeight, 1, 10000
        @camera.position.z = 4
        @active = true
        @objects = {}

        loader = new THREE.ObjectLoader()

        @renderer.setSize window.innerWidth, window.innerHeight
        document.body.appendChild @renderer.domElement
        @io = io()

        @io.on 'connect', =>
            @io.emit 'leap'

        @io.on 'message', (data) =>
            arr = data.split(' ')
            if arr[0] == 'clientId'
                @clientId = arr[1]
            else if arr[0] == 'deactivate'
                @active = false
            else if arr[0] == 'activate'
                @active = true
            else
                head = JSON.parse data
                @camera.lookAt = head.lookAt
                @camera.up = head.up

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
                for prop of object
                    old[prop] = object[prop] if prop != 'id'

        @io.on 'object', (object) =>
            unless @objects[object.object.userData.id]?
                loader.parse object, (obj3D) =>
                    @objects[object.object.userData.id] = obj3D
                    @scene.add obj3D

        # $.ajax "/sceneData",
        #     type: 'GET'
        #     contentType: 'application/json; charset=UTF-8'
        #     data: null
        #     success: (response) =>
        #         loader = new THREE.ObjectLoader()
        #         loader.parse response, (scene) =>

        options = enableGestures: true
        controller = new Leap.Controller()
        controller.setOptimizeHMD()
        Leap.loop options, (frame) =>
            for hand in frame.hands
                @io.emit 'hand', hand
        @animate()

    animate: ->
        requestAnimationFrame () =>
            @animate()
        @renderer.render @scene, @camera

Four.LeapClient = LeapClient