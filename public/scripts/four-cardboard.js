var CardboardClient, Four;

Four = {};

CardboardClient = (function() {
  function CardboardClient() {
    this.renderer = new THREE.WebGLRenderer() || new THREE.CanvasRenderer();
    this.clientId = null;
    this.scene = new THREE.Scene();
    this.camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 1, 10000);
    this.camera.position.z = 4;
    this.active = true;
    this.objects = {};
    this.pin = -1;
    this.controller = false;
    this.renderer.setSize(window.innerWidth, window.innerHeight);
    document.body.appendChild(this.renderer.domElement);
    this.io = io();
    this.setCallbacks();
  }

  CardboardClient.prototype.setCallbacks = function() {
    var effect, loader, sense;
    loader = new THREE.ObjectLoader();
    this.io.on('connect', (function(_this) {
      return function() {
        _this.io.emit('cardboard', _this.pin);
        return _this.controller = true;
      };
    })(this));
    this.io.on('message', (function(_this) {
      return function(data) {
        if (data === 'error') {
          _this.controller = false;
          _this.io.disconnect();
          return $(".clientId").show();
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
    effect.setSize(window.innerWidth, window.innerHeight);
    sense = window.sense.init();
    sense.orientation((function(_this) {
      return function(data) {
        if (_this.controller) {
          _this.camera.rotation.y = 90.0 - gamma;
          _this.camera.rotation.x = beta;
          _this.camera.rotation.z = alpha;
          return _this.io.emit('head', {
            x: rotation.x,
            y: rotation.y,
            z: rotation.z
          });
        }
      };
    })(this));
    return this.animate();
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
