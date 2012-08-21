WIDTH = 640
HEIGHT = 480

deg2rad = (degrees) ->
  degrees / 360 * 2 * Math.PI

SEGMENTS = 10

turtleGeometry = new THREE.CylinderGeometry(1, 1, 1, SEGMENTS)
normalizationMatrix = new THREE.Matrix4()
normalizationMatrix.rotateX(Math.PI / 2)
normalizationMatrix.translate(new THREE.Vector3(0, -0.5, 0))
turtleGeometry.applyMatrix(normalizationMatrix)

radiusForDistance = (covered, total) ->
  50 - 20 * (covered / total)

getPerpVec = (vec) ->
  if vec.z == 0
    new THREE.Vector3(0, 0, 1)
  else if vec.y == 0
    new THREE.Vector3(0, 1, 0)
  else
    new THREE.Vector3(0, 1, -(vec.y / vec.z))

class Turtle3D
  constructor: (@position, @direction, @up, @material, @width = 30) ->
    @direction.normalize()
    @up.normalize()
    @droppings = []
    @drawing = on

  go: (distance) ->
    newPosition = new THREE.Vector3()
    newPosition.add(@position, @direction.clone().multiplyScalar(distance))
    if @drawing
      @droppings.push({ from: @position
                      , to: newPosition
                      , material: @material
                      , width: @width })
    @position = newPosition

  yaw: (angle) ->
    rotation = new THREE.Matrix4().makeRotationAxis @up, deg2rad angle
    rotation.multiplyVector3 @direction
    @direction.normalize()

  pitch: (angle) ->
    right = new THREE.Vector3().cross(@direction, @up).normalize()
    rotation = new THREE.Matrix4().makeRotationAxis right, deg2rad angle
    rotation.multiplyVector3 @direction
    @direction.normalize()
    rotation.multiplyVector3 @up
    @up.normalize()

  roll: (angle) ->
    rotation = new THREE.Matrix4().makeRotationAxis @direction, deg2rad angle
    rotation.multiplyVector3 @up
    @up.normalize()

  penUp: ->
    @drawing = off

  penDown: ->
    @drawing = on

  setWidth: (@width) ->

  switchMaterial: (material) ->
    @material = material

  setColor: (hex) ->
    @switchMaterial(new THREE.MeshLambertMaterial({ color: hex
                                                  , ambient: hex }))

  retrieveMeshes: ->

    totalLength = _.reduce(_.map(@droppings, ({from, to}) -> from.distanceTo to),
                           (x, y) -> x + y,
                           0)
    coveredLength = 0

    for {from, to, material, width} in @droppings
      distance = from.distanceTo to

      mesh = new THREE.Mesh(turtleGeometry, material)

      bottomRadius = width
      topRadius = width
      coveredLength += distance
      height = distance
      shearFactor = (topRadius - bottomRadius) / height

      turtleTransform = new THREE.Matrix4()
      turtleTransform.translate(from)
      turtleTransform.lookAt(from, to, getPerpVec(to.clone().subSelf(from)))
      turtleTransform.multiplySelf(new THREE.Matrix4(1, shearFactor, 0, 0,
                                                     0,           1, 0, 0,
                                                     0, shearFactor, 1, 0,
                                                     0,           0, 0, 1))
      turtleTransform.scale(new THREE.Vector3(bottomRadius, bottomRadius, height))

      mesh.applyMatrix(turtleTransform)

      mesh
    


window.onload = ->

  codeMirror = CodeMirror.fromTextArea $('#codeMirrorArea').get 0

  try
    renderer = new THREE.WebGLRenderer()
  catch e
    console.log "loading WebGLRenderer failed, trying CanvasRenderer"
    renderer = new THREE.CanvasRenderer()

  renderer.setSize WIDTH, HEIGHT
  document.body.appendChild renderer.domElement


  camera = new THREE.PerspectiveCamera(75, WIDTH / HEIGHT, 0.1, 1000000)
  camera.position.set(0, 0, 1000)
  camera.lookAt(new THREE.Vector3(0, 0, 0))

  controls = new THREE.OrbitControls(camera, renderer.domElement)
  #controls.staticMoving = true
  #controls.panSpeed = 0.7

  scene = new THREE.Scene()

  animate = ->
    requestAnimationFrame animate
    controls.update()
    renderer.render scene, camera

  animate()

  $('#runButton').click ->

    material = new THREE.MeshLambertMaterial({ color: 0xFF0000
                                             , ambient: 0xFF0000 })
    
    myTurtle = new Turtle3D(new THREE.Vector3(0,0,0),
                            new THREE.Vector3(0,1,0),
                            new THREE.Vector3(0,0,1),
                            material)

    window.go = -> myTurtle.go.apply myTurtle, arguments
    window.yaw = -> myTurtle.yaw.apply myTurtle, arguments
    window.pitch = -> myTurtle.pitch.apply myTurtle, arguments
    window.roll = -> myTurtle.roll.apply myTurtle, arguments
    window.penUp = -> myTurtle.penUp.apply myTurtle, arguments
    window.penDown = -> myTurtle.penDown.apply myTurtle, arguments
    window.color = -> myTurtle.setColor.apply myTurtle, arguments
    window.width = -> myTurtle.setWidth.apply myTurtle, arguments

    eval codeMirror.getValue()

    scene = new THREE.Scene()

    meshes = myTurtle.retrieveMeshes()
    for mesh in meshes
      scene.add(mesh)

    centroid = new THREE.Vector3()
    for mesh in meshes
      centroid.addSelf(mesh.position)
    centroid.divideScalar(meshes.length)

    console.log centroid
    camera.position = new THREE.Vector3(0, 0, 1000).addSelf(centroid)
    controls.center = centroid

    dirLight = new THREE.DirectionalLight(0xFFFFFF)
    dirLight.position.set(1,1,1)
    dirLight.target.position.set(0,0,0)
    scene.add(dirLight)

    ambLight = new THREE.AmbientLight(0x555555)
    scene.add(ambLight)

    $('#numMeshes').html "#{meshes.length} meshes in the scene"
