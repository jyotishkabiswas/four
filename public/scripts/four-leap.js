var Four, LeapClient;

Four = {};

LeapClient = (function() {
  function LeapClient(url) {
    var loader;
    this.url = url;
    this.renderer = new THREE.WebGLRenderer() || new THREE.CanvasRenderer();
    this.clientId = null;
    this.scene = new THREE.Scene();
    this.camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 1, 10000);
    this.camera.position.z = 4;
    this.active = true;
    this.objects = {};
    loader = new THREE.ObjectLoader();
    this.renderer.setSize(window.innerWidth, window.innerHeight);
    document.body.appendChild(this.renderer.domElement);
    this.io = io();
    this.io.on('connect', (function(_this) {
      return function() {
        return _this.io.emit('leap');
      };
    })(this));
    this.io.on('message', (function(_this) {
      return function(data) {
        var arr, head;
        arr = data.split(' ');
        if (arr[0] === 'clientId') {
          return _this.clientId = arr[1];
        } else if (arr[0] === 'deactivate') {
          return _this.active = false;
        } else if (arr[0] === 'activate') {
          return _this.active = true;
        } else {
          head = JSON.parse(data);
          _this.camera.lookAt = head.lookAt;
          return _this.camera.up = head.up;
        }
      };
    })(this));
    this.io.on('add', (function(_this) {
      return function(object) {
        return loader.parse(object, function(obj3D) {
          _this.scene.add(obj3D);
          return _this.objects[object.uuid] = obj3D;
        });
      };
    })(this));
    this.io.on('remove', (function(_this) {
      return function(uuid) {
        var toRemove;
        toRemove = _this.objects[uuid];
        _this.scene.remove(toRemove);
        return delete _this.objects[uuid];
      };
    })(this));
    this.io.on('update', (function(_this) {
      return function(object) {
        var old, prop, results;
        old = _this.objects[object.uuid];
        if (old == null) {
          return _this.io.emit('info', {
            id: object.id
          });
        } else {
          results = [];
          for (prop in object.props) {
            if (prop !== 'id') {
              results.push(old[prop] = object[prop]);
            } else {
              results.push(void 0);
            }
          }
          return results;
        }
      };
    })(this));
    this.io.on('object', (function(_this) {
      return function(object) {
        console.log(object.uuid);
        if (_this.objects[object.uuid] == null) {
          return loader.parse(object, function(obj3D) {
            _this.objects[object.uuid] = obj3D;
            return _this.scene.add(obj3D);
          });
        }
      };
    })(this));
    this.animate();
  }

  LeapClient.prototype.animate = function() {
    requestAnimationFrame((function(_this) {
      return function() {
        return _this.animate();
      };
    })(this));
    return this.renderer.render(this.scene, this.camera);
  };

  return LeapClient;

})();

Four.LeapClient = LeapClient;
