path = require 'path'
THREE = require 'three'

isMobile = (req) ->
    ua = req.headers['user-agent'].toLowerCase()
    /(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows (ce|phone)|xda|xiino/i.test(ua) or /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(ua.substr(0, 4))

class SceneManager

    constructor: (@app, @io, @scene, updateFn) ->
        @codeToLeap = {}
        @cardboardToLeap = {}
        @leapToCardboard = {}
        @playerObjects = []

        @scene = @scene || new Physi.Scene()
        if updateFn?
            @updateFn = updateFn.bind @
        else
            @updateFn = =>
        @io.on 'connection', (socket) =>
            @initializeConnection socket

        @app.get '/', (req, res) ->
            if isMobile req
                res.sendFile path.join(__dirname, '../views/cardboard.html')
            else
                res.sendFile path.join(__dirname, '../views/leap.html')
        @app.get '/sceneData', (req, res) =>
            console.log "Sending scene data..."
            res.send @scene.toJSON()

        @animate()

    initializeConnection: (socket) ->
        x = Math.floor(Math.random() * (9999 - 1000) + 1000)
        while x of @codeToLeap
            x = Math.floor(Math.random() * (9999 - 1000) + 1000)

        socket.on 'disconnect', =>
            if socket of @leapToCardboard
                cbSocket = @leapToCardboard[socket]
                cbSocket.send 'error'
                delete @cardboardToLeap[cbSocket]
                delete @leapToCardboard[socket]
            else if @codeToLeap[x]?
                delete @codeToLeap[x]
            else
                leap = @cardboardToLeap[x]
                leap.send 'activate'
                delete @leapToCardboard[leap]
                delete @cardboardtoLeap[socket]

        socket.on 'leap', () =>
            if @playerObjects.length > 1
                return
            else if @playerObjects.length == 1
                @playerObjects.push new Head(new THREE.Vector3(0, 4, -13))
            @codeToLeap[x] = socket
            socket.send "clientId #{x}"
            return

        socket.on 'cardboard', (x) =>
            code = parseInt data.split()[1]
            unless code of @leapClients
                socket.send 'error'
            leap = @leapClients[code]
            if leap of @leapToCardboard
                socket.send 'error'
            # create mappings between leap and cardboard
            leap.send 'deactivate'
            @cardboardtoLeap[socket] = @codeToLeap[code]
            @leapToCardboard[leap] = @cardboardtoLeap[socket]

        socket.on 'info', (data) =>
            obj = @scene.getObjectById(data.id)
            obj.userData.id = obj.id
            if obj?
                @io.emit 'object', obj

        # updating hand
        socket.on 'hand', (leapHand) =>
            @playerObjects[socket].head[leapHand.type] = hand

        # updating head
        socket.on 'head', (data) =>
            @cardboardToLeap[socket].send data # send head position to correct client
            @playerObjects[socket].head.lookAt = data.lookAt
            @playerObjects[socket].head.up = data.up

        socket.on 'error', (data) =>

    add: (object) ->
        @scene.add object
        object.userData.id = object.id # hack for synchronization
        @io.emit 'add', object

    remove: (object) ->
        @scene.remove object
        id = object.id
        object = object.toJSON()
        object.id = object.id
        @io.emit 'remove', object.id

    # to be called whenever an object is mutated
    update: (object) ->
        @io.emit 'update', object

    animate: ->
        @updateFn()
        setTimeout @animate.bind @, 200

module.exports = SceneManager