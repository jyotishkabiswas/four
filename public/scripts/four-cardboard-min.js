var CardboardCamera,extend=function(a,b){function c(){this.constructor=a}for(var d in b)hasProp.call(b,d)&&(a[d]=b[d]);return c.prototype=b.prototype,a.prototype=new c,a.__super__=b.prototype,a},hasProp={}.hasOwnProperty;CardboardCamera=function(a){function b(){}return extend(b,a),b}(THREE.Camera);var createMesh,getMesh,spareMeshes;spareMeshes={left:[],right:[]},createMesh=function(a){var b,c,d;return b=(new THREE.JSONLoader).parse(a),b.materials[0].skinning=!0,b.materials[0].transparent=!0,b.materials[0].opacity=.7,b.materials[0].emissive.setHex(8947848),b.materials[0].vertexColors=THREE.VertexColors,b.materials[0].depthTest=!0,_extend(b.materials[0],scope.materialOptions),_extend(b.geometry,scope.geometryOptions),c=new THREE.SkinnedMesh(b.geometry,b.materials[0]),c.positionRaw=new THREE.Vector3,c.fingers=c.children[0].children,c.castShadow=!0,c.bonesBySkinIndex={},d=0,c.children[0].traverse(function(a){return a.skinIndex=d,c.bonesBySkinIndex[d]=a,d++}),c.boneLabels={},scope.boneLabels&&c.traverse(function(a){var b,d,e,f,g,h,i;e=(d=c.boneLabels)[f=a.id]||(d[f]=document.createElement("div")),e.style.position="absolute",e.style.zIndex="10",e.style.color="white",e.style.fontSize="20px",e.style.textShadow="0px 0px 3px black",e.style.fontFamily="helvetica",e.style.textAlign="center",g=scope.labelAttributes,h=[];for(b in g)i=g[b],h.push(e.setAttribute(b,i));return h}),c.screenPosition=function(a){var b,c,d,e;return b=scope.camera,console.assert(b instanceof THREE.Camera,"screenPosition expects camera, got",b),e=parseInt(window.getComputedStyle(scope.renderer.domElement).width,10),c=parseInt(window.getComputedStyle(scope.renderer.domElement).height,10),console.assert(e&&c),d=new THREE.Vector3,a instanceof THREE.Vector3?d.fromArray(a.toArray()):d.fromArray(a).sub(this.positionRaw).add(this.position),d.project(b),d.x=d.x*e/2+e/2,d.y=d.y*c/2+c/2,console.assert(!isNaN(d.x)&&!isNaN(d.x),"x/y screen position invalid"),d},c.scenePosition=function(a,b){return b.fromArray(a).sub(c.positionRaw).add(c.position)},c.scaleFromHand=function(a){var b,d;return b=(new THREE.Vector3).subVectors((new THREE.Vector3).fromArray(a.fingers[2].pipPosition),(new THREE.Vector3).fromArray(a.fingers[2].mcpPosition)).length(),d=c.fingers[2].position.length(),c.leapScale=b/d,c.scale.set(c.leapScale,c.leapScale,c.leapScale)},c},getMesh=function(a){var b,c,d;return d=spareMeshes[a.type],d.length>0?c=d.pop():(b=rigs[a.type],c=createMesh(b)),c};