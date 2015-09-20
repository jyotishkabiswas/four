# adapted from https://github.com/leapmotion/leapjs-rigged-hand/blob/master/src/leap.rigged-hand.coffee
spareMeshes =
    left: []
    right: []

class HandAdapter

    constructor: (@scope = {}) ->
        @left = null
        @right = null

    # converts a ThreeJS JSON blob in to a mesh
    createMesh: (JSON)->
        # note: this causes a good 90ms pause on first run
        # it appears as if mesh.clone does not clone material and geometry, so at this point we refrain from doing so
        # see THREE.SkinnedMesh.prototype.clone
        # instead, we call createMesh right off, to have the results "cached"
        data = (new THREE.JSONLoader).parse JSON
        data.materials[0].skinning = true
        data.materials[0].transparent = true
        data.materials[0].opacity = 0.7
        data.materials[0].emissive.setHex(0x888888)

        data.materials[0].vertexColors = THREE.VertexColors
        data.materials[0].depthTest = true

        _extend(data.materials[0], @scope.materialOptions)
        _extend(data.geometry,         @scope.geometryOptions)
        handMesh = new THREE.SkinnedMesh(data.geometry, data.materials[0])
        handMesh.positionRaw = new THREE.Vector3
        handMesh.fingers = handMesh.children[0].children
        handMesh.castShadow = true

        # Re-create the skin index on bones in a manner which will be accessible later
        handMesh.bonesBySkinIndex = {}
        i = 0
        handMesh.children[0].traverse (bone)->
            bone.skinIndex = i
            handMesh.bonesBySkinIndex[i] = bone
            i++

        handMesh.boneLabels = {}

        if @scope.boneLabels
            handMesh.traverse (bone)->
                label = handMesh.boneLabels[bone.id] ||= document.createElement('div')
                label.style.position = 'absolute'
                label.style.zIndex = '10'

                label.style.color = 'white'
                label.style.fontSize = '20px'
                label.style.textShadow = '0px 0px 3px black'
                label.style.fontFamily = 'helvetica'
                label.style.textAlign = 'center'

                for attribute, value of @scope.labelAttributes
                    label.setAttribute(attribute, value)


        # takes in a vec3 of leap coordinates, and converts them in to screen position,
        # based on the hand mesh position and camera position.
        # accepts optional width and height values, which default to
        handMesh.screenPosition = (position)->

            camera = @scope.camera
            console.assert(camera instanceof THREE.Camera, "screenPosition expects camera, got", camera)

            width =    parseInt(window.getComputedStyle(@scope.renderer.domElement).width,    10)
            height = parseInt(window.getComputedStyle(@scope.renderer.domElement).height, 10)
            console.assert(width && height)

            screenPosition = new THREE.Vector3()

            if position instanceof THREE.Vector3
                screenPosition.fromArray(position.toArray())
            else
                screenPosition.fromArray(position)
                    # the palm may have its base position scaled on top of leap coordinates:
                    .sub(@positionRaw)
                    .add(@position)

            screenPosition.project(camera)
            screenPosition.x = (screenPosition.x * width / 2) + width / 2
            screenPosition.y = (screenPosition.y * height / 2) + height / 2

            console.assert(!isNaN(screenPosition.x) && !isNaN(screenPosition.x), 'x/y screen position invalid')

            screenPosition

        handMesh.scenePosition = (leapPosition, scenePosition) ->
            scenePosition.fromArray(leapPosition)
                # these two add the base offset, factoring in for positionScale
                .sub(handMesh.positionRaw)
                .add(handMesh.position)

        # Mesh scale set by comparing leap first bone length to mesh first bone length
        handMesh.scaleFromHand = (leapHand) ->
            middleProximalLeapLength = (new THREE.Vector3).subVectors(
                (new THREE.Vector3).fromArray(leapHand.fingers[2].pipPosition)
                (new THREE.Vector3).fromArray(leapHand.fingers[2].mcpPosition)
            ).length()
            # skinnedmesh positions are relative distances to the parent bone
            middleProximalMeshLength = handMesh.fingers[2].position.length()

            handMesh.leapScale = ( middleProximalLeapLength / middleProximalMeshLength )
            handMesh.scale.set( handMesh.leapScale, handMesh.leapScale, handMesh.leapScale )

        handMesh

    getMesh: (leapHand)->
        # Meshes are kept in memory after first-use, as it takes about 24ms, or two frames, to add one to the screen
        # on a good computer.
        meshes = @spareMeshes[leapHand.type]
        if meshes.length > 0
            handMesh = meshes.pop()
        else
            JSON = @rigs[leapHand.type]
            handMesh = @createMesh(JSON)

        handMesh

    frameAction: (leapHand) ->

        # this works around a subtle bug where non-extended fingers would appear after extended ones
        leapHand.fingers = _sortBy(leapHand.fingers, (finger)-> finger.id)
        if leapHand.type == 'left'
            handmesh = @left || getMesh(leapHand)
            unless @left?
                @scope.scene.add handmesh
            @left = handmesh
        else
            handmesh = @right || getMesh(leapHand)
            unless @right?
                @scope.scene.add handmesh
            @right = handmesh

        palm = handMesh.children[0]

        handMesh.scaleFromHand(leapHand)

        palm.positionLeap.fromArray(leapHand.palmPosition)

        # wrist -> mcp -> pip -> dip -> tip
        for mcp, i in palm.children
            mcp.        positionLeap.fromArray(leapHand.fingers[i].mcpPosition)
            mcp.pip.positionLeap.fromArray(leapHand.fingers[i].pipPosition)
            mcp.dip.positionLeap.fromArray(leapHand.fingers[i].dipPosition)
            mcp.tip.positionLeap.fromArray(leapHand.fingers[i].tipPosition)


        # set heading on palm so that finger.parent can access
        palm.worldDirection.fromArray(leapHand.direction)
        palm.up.fromArray(leapHand.palmNormal).multiplyScalar(-1)
        palm.worldUp.fromArray(leapHand.palmNormal).multiplyScalar(-1)

        # hand mesh (root is where) is set to the palm position
        # this should mean it would move in sync with a fixed offset
        handMesh.positionRaw.fromArray(leapHand.palmPosition)
        handMesh.position.copy(handMesh.positionRaw).multiplyScalar(@scope.positionScale)

        handMesh.matrix.lookAt(palm.worldDirection, zeroVector, palm.up)

        # set worldQuaternion before using it to position fingers (threejs updates handMesh.quaternion, but only too late)
        palm.worldQuaternion.setFromRotationMatrix( handMesh.matrix )

        for mcp in palm.children
            mcp.traverse (bone)->
                if bone.children[0]
                    bone.worldDirection.subVectors(bone.children[0].positionLeap, bone.positionLeap).normalize()
                    bone.positionFromWorld(bone.children[0].positionLeap, bone.positionLeap)

        if handMesh.helper
            handMesh.helper.update()

        # @scope.positionDots(leapHand, handMesh)

        if @scope.boneLabels
            palm.traverse (bone)->
                # the condition here is necessary in case @scope.boneLabels is set while a hand is in the frame
                if element = handMesh.boneLabels[bone.id]
                    screenPosition = handMesh.screenPosition(bone.positionLeap, @scope.camera)
                    element.style.left = "#{screenPosition.x}px"
                    element.style.bottom = "#{screenPosition.y}px"
                    element.innerHTML = @scope.boneLabels(bone, leapHand) || ''

        if @scope.boneColors
            geometry = handMesh.geometry
            # H.    S controlled by weights, Lightness constant.
            boneColors = {}

            i = 0
            while i < geometry.vertices.length
                # 0-index at palm id
                # boneColors must return an array with [hue, saturation, lightness]
                boneColors[geometry.skinIndices[i].x] ||= (@scope.boneColors(handMesh.bonesBySkinIndex[geometry.skinIndices[i].x], leapHand) || {hue: 0, saturation: 0})
                boneColors[geometry.skinIndices[i].y] ||= (@scope.boneColors(handMesh.bonesBySkinIndex[geometry.skinIndices[i].y], leapHand) || {hue: 0, saturation: 0})
                xBoneHSL = boneColors[geometry.skinIndices[i].x]
                yBoneHSL = boneColors[geometry.skinIndices[i].y]
                weights = geometry.skinWeights[i]

                # the best way to do this would be additive blending of hue based upon weights
                # currently, we just hue to whichever is set
                hue = xBoneHSL.hue || yBoneHSL.hue
                lightness = xBoneHSL.lightness || yBoneHSL.lightness || 0.5

                saturation =
                    (xBoneHSL.saturation) * weights.x +
                    (yBoneHSL.saturation) * weights.y


                geometry.colors[i] ||= new THREE.Color()
                geometry.colors[i].setHSL(hue, saturation, lightness)
                i++
            geometry.colorsNeedUpdate = true

            # copy vertex colors to the face
            faceIndices = 'abc'
            for face in geometry.faces
                j = 0
                while j < 3
                    face.vertexColors[j] = geometry.colors[face[faceIndices[j]]]
                    j++