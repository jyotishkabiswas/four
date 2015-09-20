Four = {}

class LeapClient

    constructor: (@url) ->

        @renderer = new THREE.WebGLRenderer() || new THREE.CanvasRenderer()

        @clientId = null
        @scene = null
        @camera = new THREE.PerspectiveCamera 75, window.innerWidth / window.innerHeight, 1, 10000
        @camera.position.z = 400


        $.ajax "/sceneData",
            type: 'GET'
            contentType: 'application/json; charset=UTF-8'
            data: null
            success: (response) =>
                loader = new THREE.ObjectLoader()
                loader.parse response, (scene) =>
                    @scene = scene
                    @renderer.setSize window.innerWidth, window.innerHeight

                    @io = io @url

                    @io.on 'connect', =>
                        @io.send 'leap'

                    @io.on 'message', (data) =>
                        arr = data.split(' ')
                        if arr[0] == 'clientId'
                            @clientId = arr[1]
                        else
                            head = JSON.parse data
                            @camera.lookAt = head.lookAt
                            @camera.up = head.up

                    @io.on 'add', (object) =>
                        @scene.add object

                    @io.on 'remove', (object) =>
                        @scene.remove object

                    @io.on 'update', (object) =>
                        old = @scene.getObjectById(object.id)
                        @scene.remove old
                        @scene.add object

                    @animate()

    animate: ->
        requestAnimationFrame @animate
        @renderer.render @scene, @camera

Four.LeapClient = LeapClient