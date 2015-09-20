var Four, LeapClient;

Four = {};

LeapClient = (function() {
  function LeapClient(url) {
    this.url = url;
    this.renderer = new THREE.WebGLRenderer() || new THREE.CanvasRenderer();
    this.clientId = null;
    this.scene = null;
    this.camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 1, 10000);
    this.camera.position.z = 400;
    $.ajax("/sceneData", {
      type: 'GET',
      contentType: 'application/json; charset=UTF-8',
      data: null,
      success: (function(_this) {
        return function(response) {
          var loader;
          loader = new THREE.ObjectLoader();
          return loader.parse(response, function(scene) {
            _this.scene = scene;
            _this.renderer.setSize(window.innerWidth, window.innerHeight);
            _this.io = io(_this.url);
            _this.io.on('connect', function() {
              return _this.io.send('leap');
            });
            _this.io.on('message', function(data) {
              var arr, head;
              arr = data.split(' ');
              if (arr[0] === 'clientId') {
                return _this.clientId = arr[1];
              } else {
                head = JSON.parse(data);
                _this.camera.lookAt = head.lookAt;
                return _this.camera.up = head.up;
              }
            });
            _this.io.on('add', function(object) {
              return _this.scene.add(object);
            });
            _this.io.on('remove', function(object) {
              return _this.scene.remove(object);
            });
            _this.io.on('update', function(object) {
              var old;
              old = _this.scene.getObjectById(object.id);
              _this.scene.remove(old);
              return _this.scene.add(object);
            });
            return _this.animate();
          });
        };
      })(this)
    });
  }

  LeapClient.prototype.animate = function() {
    requestAnimationFrame(this.animate);
    return this.renderer.render(this.scene, this.camera);
  };

  return LeapClient;

})();

Four.LeapClient = LeapClient;
