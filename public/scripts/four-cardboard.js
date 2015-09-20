var CardboardCamera,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

CardboardCamera = (function(superClass) {
  extend(CardboardCamera, superClass);

  function CardboardCamera() {}

  return CardboardCamera;

})(THREE.Camera);

var CardboardClient, Four;

Four = {};

CardboardClient = (function() {
  function CardboardClient() {
    var loader;
    this.renderer = new THREE.WebGLRenderer() || new THREE.CanvasRenderer();
    this.clientId = null;
    this.scene = new THREE.Scene();
    this.camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 1, 10000);
    this.camera.position.z = 4;
    this.active = true;
    this.objects = {};
    this.pin = -1;
    this.handAdapter = new HandAdapter(this);
    adapter;
    loader = new THREE.ObjectLoader();
    this.renderer.setSize(window.innerWidth, window.innerHeight);
    document.body.appendChild(this.renderer.domElement);
    this.io = io();
    this.setCallbacks();
  }

  CardboardClient.prototype.setCallbacks = function() {
    var effect;
    this.io.on('connect', (function(_this) {
      return function() {
        return _this.io.emit('cardboard', _this.pin);
      };
    })(this));
    this.io.on('message', (function(_this) {
      return function(data) {
        if (data === 'error') {
          _this.io.disconnect();
          return $(".clientId").show();
        } else {
          return _this.handAdapter.frameAction(JSON.parse(data));
        }
      };
    })(this));
    this.io.on('add', (function(_this) {
      return function(object) {
        return loader.parse(object, function(obj3D) {
          _this.scene.add(obj3D);
          return _this.objects[object.object.userData.id] = obj3D;
        });
      };
    })(this));
    this.io.on('remove', (function(_this) {
      return function(id) {
        var toRemove;
        toRemove = _this.objects[id];
        _this.scene.remove(toRemove);
        return delete _this.objects[id];
      };
    })(this));
    this.io.on('update', (function(_this) {
      return function(object) {
        var old, pos, rot;
        old = _this.objects[object.id];
        if (old == null) {
          return _this.io.emit('info', {
            id: object.id
          });
        } else {
          pos = object.position;
          rot = object.rotation;
          old.rotation.set(rot.x, rot.y, rot.z, rot.order);
          return old.position.set(pos.x, pos.y, pos.z);
        }
      };
    })(this));
    this.io.on('object', (function(_this) {
      return function(object) {
        if (_this.objects[object.object.userData.id] == null) {
          return loader.parse(object, function(obj3D) {
            _this.objects[object.object.userData.id] = obj3D;
            return _this.scene.add(obj3D);
          });
        }
      };
    })(this));
    effect = new THREE.StereoEffect(renderer);
    effect.eyeSeparation = 10;
    return effect.setSize(window.innerWidth, window.innerHeight);
  };

  CardboardClient.prototype.setPinAndConnect = function() {
    this.pin = $("input#pinInput").val();
    return $(".clientId").hide();
  };

  CardboardClient.prototype.reconnect = function() {
    this.io = io();
    return this.setCallbacks();
  };

  CardboardClient.prototype.animate = function() {
    requestAnimationFrame((function(_this) {
      return function() {
        return _this.animate();
      };
    })(this));
    return this.renderer.render(this.scene, this.camera);
  };

  return CardboardClient;

})();

Four.CardboardClient = CardboardClient;

var HandAdapter, spareMeshes;

spareMeshes = {
  left: [],
  right: []
};

HandAdapter = (function() {
  function HandAdapter(scope) {
    this.scope = scope != null ? scope : {};
    this.left = null;
    this.right = null;
  }

  HandAdapter.prototype.createMesh = function(JSON) {
    var data, handMesh, i;
    data = (new THREE.JSONLoader).parse(JSON);
    data.materials[0].skinning = true;
    data.materials[0].transparent = true;
    data.materials[0].opacity = 0.7;
    data.materials[0].emissive.setHex(0x888888);
    data.materials[0].vertexColors = THREE.VertexColors;
    data.materials[0].depthTest = true;
    _extend(data.materials[0], this.scope.materialOptions);
    _extend(data.geometry, this.scope.geometryOptions);
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
    if (this.scope.boneLabels) {
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
        ref = this.scope.labelAttributes;
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
      camera = this.scope.camera;
      console.assert(camera instanceof THREE.Camera, "screenPosition expects camera, got", camera);
      width = parseInt(window.getComputedStyle(this.scope.renderer.domElement).width, 10);
      height = parseInt(window.getComputedStyle(this.scope.renderer.domElement).height, 10);
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

  HandAdapter.prototype.getMesh = function(leapHand) {
    var JSON, handMesh, meshes;
    meshes = this.spareMeshes[leapHand.type];
    if (meshes.length > 0) {
      handMesh = meshes.pop();
    } else {
      JSON = this.rigs[leapHand.type];
      handMesh = this.createMesh(JSON);
    }
    return handMesh;
  };

  HandAdapter.prototype.frameAction = function(leapHand) {
    var base, boneColors, face, faceIndices, geometry, handmesh, hue, i, j, k, l, len, len1, len2, lightness, m, mcp, name, name1, palm, ref, ref1, ref2, results, saturation, weights, xBoneHSL, yBoneHSL;
    leapHand.fingers = _sortBy(leapHand.fingers, function(finger) {
      return finger.id;
    });
    if (leapHand.type === 'left') {
      handmesh = this.left || getMesh(leapHand);
      if (this.left == null) {
        this.scope.scene.add(handmesh);
      }
      this.left = handmesh;
    } else {
      handmesh = this.right || getMesh(leapHand);
      if (this.right == null) {
        this.scope.scene.add(handmesh);
      }
      this.right = handmesh;
    }
    palm = handMesh.children[0];
    handMesh.scaleFromHand(leapHand);
    palm.positionLeap.fromArray(leapHand.palmPosition);
    ref = palm.children;
    for (i = k = 0, len = ref.length; k < len; i = ++k) {
      mcp = ref[i];
      mcp.positionLeap.fromArray(leapHand.fingers[i].mcpPosition);
      mcp.pip.positionLeap.fromArray(leapHand.fingers[i].pipPosition);
      mcp.dip.positionLeap.fromArray(leapHand.fingers[i].dipPosition);
      mcp.tip.positionLeap.fromArray(leapHand.fingers[i].tipPosition);
    }
    palm.worldDirection.fromArray(leapHand.direction);
    palm.up.fromArray(leapHand.palmNormal).multiplyScalar(-1);
    palm.worldUp.fromArray(leapHand.palmNormal).multiplyScalar(-1);
    handMesh.positionRaw.fromArray(leapHand.palmPosition);
    handMesh.position.copy(handMesh.positionRaw).multiplyScalar(this.scope.positionScale);
    handMesh.matrix.lookAt(palm.worldDirection, zeroVector, palm.up);
    palm.worldQuaternion.setFromRotationMatrix(handMesh.matrix);
    ref1 = palm.children;
    for (l = 0, len1 = ref1.length; l < len1; l++) {
      mcp = ref1[l];
      mcp.traverse(function(bone) {
        if (bone.children[0]) {
          bone.worldDirection.subVectors(bone.children[0].positionLeap, bone.positionLeap).normalize();
          return bone.positionFromWorld(bone.children[0].positionLeap, bone.positionLeap);
        }
      });
    }
    if (handMesh.helper) {
      handMesh.helper.update();
    }
    if (this.scope.boneLabels) {
      palm.traverse(function(bone) {
        var element, screenPosition;
        if (element = handMesh.boneLabels[bone.id]) {
          screenPosition = handMesh.screenPosition(bone.positionLeap, this.scope.camera);
          element.style.left = screenPosition.x + "px";
          element.style.bottom = screenPosition.y + "px";
          return element.innerHTML = this.scope.boneLabels(bone, leapHand) || '';
        }
      });
    }
    if (this.scope.boneColors) {
      geometry = handMesh.geometry;
      boneColors = {};
      i = 0;
      while (i < geometry.vertices.length) {
        boneColors[name = geometry.skinIndices[i].x] || (boneColors[name] = this.scope.boneColors(handMesh.bonesBySkinIndex[geometry.skinIndices[i].x], leapHand) || {
          hue: 0,
          saturation: 0
        });
        boneColors[name1 = geometry.skinIndices[i].y] || (boneColors[name1] = this.scope.boneColors(handMesh.bonesBySkinIndex[geometry.skinIndices[i].y], leapHand) || {
          hue: 0,
          saturation: 0
        });
        xBoneHSL = boneColors[geometry.skinIndices[i].x];
        yBoneHSL = boneColors[geometry.skinIndices[i].y];
        weights = geometry.skinWeights[i];
        hue = xBoneHSL.hue || yBoneHSL.hue;
        lightness = xBoneHSL.lightness || yBoneHSL.lightness || 0.5;
        saturation = xBoneHSL.saturation * weights.x + yBoneHSL.saturation * weights.y;
        (base = geometry.colors)[i] || (base[i] = new THREE.Color());
        geometry.colors[i].setHSL(hue, saturation, lightness);
        i++;
      }
      geometry.colorsNeedUpdate = true;
      faceIndices = 'abc';
      ref2 = geometry.faces;
      results = [];
      for (m = 0, len2 = ref2.length; m < len2; m++) {
        face = ref2[m];
        j = 0;
        results.push((function() {
          var results1;
          results1 = [];
          while (j < 3) {
            face.vertexColors[j] = geometry.colors[face[faceIndices[j]]];
            results1.push(j++);
          }
          return results1;
        })());
      }
      return results;
    }
  };

  return HandAdapter;

})();
