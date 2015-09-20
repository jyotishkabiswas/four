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
                @objects[object.uuid] = obj3D

        @io.on 'remove', (uuid) =>
            toRemove = @objects[uuid]
            @scene.remove toRemove
            delete @objects[uuid]

        @io.on 'update', (object) =>
            old = @objects[object.uuid]
            unless old?
                @io.emit 'info', {id: object.id}
            else
                for prop of object.props
                    old[prop] = object[prop] if prop != 'id'

        @io.on 'object', (object) =>
            unless @objects[object.uuid]?
                loader.parse object, (obj3D) =>
                    @objects[object.uuid] = obj3D
                    @scene.add obj3D

        # $.ajax "/sceneData",
        #     type: 'GET'
        #     contentType: 'application/json; charset=UTF-8'
        #     data: null
        #     success: (response) =>
        #         loader = new THREE.ObjectLoader()
        #         loader.parse response, (scene) =>



        @animate()

    animate: ->
        requestAnimationFrame () =>
            @animate()
        @renderer.render @scene, @camera

Four.LeapClient = LeapClient