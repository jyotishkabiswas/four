THREE = require 'three'

class Head extends THREE.Camera

    constructor: (@pos) ->
        @rotation = new THREE.Rotation()
        @hands =
            left: null
            right: null