var CardboardCamera,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

CardboardCamera = (function(superClass) {
  extend(CardboardCamera, superClass);

  function CardboardCamera() {}

  return CardboardCamera;

})(THREE.Camera);

var createMesh, getMesh, spareMeshes;

spareMeshes = {
  left: [],
  right: []
};

createMesh = function(JSON) {
  var data, handMesh, i;
  data = (new THREE.JSONLoader).parse(JSON);
  data.materials[0].skinning = true;
  data.materials[0].transparent = true;
  data.materials[0].opacity = 0.7;
  data.materials[0].emissive.setHex(0x888888);
  data.materials[0].vertexColors = THREE.VertexColors;
  data.materials[0].depthTest = true;
  _extend(data.materials[0], scope.materialOptions);
  _extend(data.geometry, scope.geometryOptions);
  handMesh = new THREE.SkinnedMesh(data.geometry, data.materials[0]);
  handMesh.positionRaw = new THREE.Vector3;
  handMesh.fingers = handMesh.children[0].children;
  handMesh.castShadow = true;
  handMesh.bonesBySkinIndex = {};
  i = 0;
  handMesh.children[0].traverse(function(bone) {
    bone.skinIndex = i;
    handMesh.bonesBySkinIndex[i] = bone;
    return i++;
  });
  handMesh.boneLabels = {};
  if (scope.boneLabels) {
    handMesh.traverse(function(bone) {
      var attribute, base, label, name, ref, results, value;
      label = (base = handMesh.boneLabels)[name = bone.id] || (base[name] = document.createElement('div'));
      label.style.position = 'absolute';
      label.style.zIndex = '10';
      label.style.color = 'white';
      label.style.fontSize = '20px';
      label.style.textShadow = '0px 0px 3px black';
      label.style.fontFamily = 'helvetica';
      label.style.textAlign = 'center';
      ref = scope.labelAttributes;
      results = [];
      for (attribute in ref) {
        value = ref[attribute];
        results.push(label.setAttribute(attribute, value));
      }
      return results;
    });
  }
  handMesh.screenPosition = function(position) {
    var camera, height, screenPosition, width;
    camera = scope.camera;
    console.assert(camera instanceof THREE.Camera, "screenPosition expects camera, got", camera);
    width = parseInt(window.getComputedStyle(scope.renderer.domElement).width, 10);
    height = parseInt(window.getComputedStyle(scope.renderer.domElement).height, 10);
    console.assert(width && height);
    screenPosition = new THREE.Vector3();
    if (position instanceof THREE.Vector3) {
      screenPosition.fromArray(position.toArray());
    } else {
      screenPosition.fromArray(position).sub(this.positionRaw).add(this.position);
    }
    screenPosition.project(camera);
    screenPosition.x = (screenPosition.x * width / 2) + width / 2;
    screenPosition.y = (screenPosition.y * height / 2) + height / 2;
    console.assert(!isNaN(screenPosition.x) && !isNaN(screenPosition.x), 'x/y screen position invalid');
    return screenPosition;
  };
  handMesh.scenePosition = function(leapPosition, scenePosition) {
    return scenePosition.fromArray(leapPosition).sub(handMesh.positionRaw).add(handMesh.position);
  };
  handMesh.scaleFromHand = function(leapHand) {
    var middleProximalLeapLength, middleProximalMeshLength;
    middleProximalLeapLength = (new THREE.Vector3).subVectors((new THREE.Vector3).fromArray(leapHand.fingers[2].pipPosition), (new THREE.Vector3).fromArray(leapHand.fingers[2].mcpPosition)).length();
    middleProximalMeshLength = handMesh.fingers[2].position.length();
    handMesh.leapScale = middleProximalLeapLength / middleProximalMeshLength;
    return handMesh.scale.set(handMesh.leapScale, handMesh.leapScale, handMesh.leapScale);
  };
  return handMesh;
};

getMesh = function(leapHand) {
  var JSON, handMesh, meshes;
  meshes = spareMeshes[leapHand.type];
  if (meshes.length > 0) {
    handMesh = meshes.pop();
  } else {
    JSON = rigs[leapHand.type];
    handMesh = createMesh(JSON);
  }
  return handMesh;
};
