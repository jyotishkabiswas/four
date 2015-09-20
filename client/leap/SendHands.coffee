socket = io.connect('http://localhost') #Enter server address here
options = enableGestures: true
controller = Leap.Controller()
controller.set_policy Leap.Controller.POLICY_OPTIMIZE_HMD
Leap.loop options, (frame) ->
  socket.send 'hands', frame.hands
  return