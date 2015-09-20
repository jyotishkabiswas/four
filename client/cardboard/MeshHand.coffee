spareMeshes = {
    left: [],
    right: []
}

# converts a ThreeJS JSON blob in to a mesh
createMesh = (JSON)->
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

    _extend(data.materials[0], scope.materialOptions)
    _extend(data.geometry,         scope.geometryOptions)
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

    if scope.boneLabels
        handMesh.traverse (bone)->
            label = handMesh.boneLabels[bone.id] ||= document.createElement('div')
            label.style.position = 'absolute'
            label.style.zIndex = '10'

            label.style.color = 'white'
            label.style.fontSize = '20px'
            label.style.textShadow = '0px 0px 3px black'
            label.style.fontFamily = 'helvetica'
            label.style.textAlign = 'center'

            for attribute, value of scope.labelAttributes
                label.setAttribute(attribute, value)


    # takes in a vec3 of leap coordinates, and converts them in to screen position,
    # based on the hand mesh position and camera position.
    # accepts optional width and height values, which default to
    handMesh.screenPosition = (position)->

        camera = scope.camera
        console.assert(camera instanceof THREE.Camera, "screenPosition expects camera, got", camera)

        width =    parseInt(window.getComputedStyle(scope.renderer.domElement).width,    10)
        height = parseInt(window.getComputedStyle(scope.renderer.domElement).height, 10)
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

getMesh = (leapHand)->
    # Meshes are kept in memory after first-use, as it takes about 24ms, or two frames, to add one to the screen
    # on a good computer.
    meshes = spareMeshes[leapHand.type]
    if meshes.length > 0
        handMesh = meshes.pop()
    else
        JSON = rigs[leapHand.type]
        handMesh = createMesh(JSON)

    handMesh