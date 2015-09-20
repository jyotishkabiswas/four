THREE = require 'three'

class Head extends THREE.Camera

    constructor: ->
        @hands =
            left: null
            right: null
