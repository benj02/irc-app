PORT = 3000
PROD = false

http = require "http"
path = require "path"
fs = require "fs"
request = require "request"

socketio = require "socket.io"
express = require "express"
BodyParser = require "body-parser"

app = express()
server = http.createServer app
io = socketio.listen server

app.use express.static(path.resolve(__dirname, "static"))
app.use BodyParser.json()
app.use BodyParser.urlencoded extended: true

app.set "view engine", "ejs"

sockets = []
broadcast = (event, data) ->
  socket.emit event, data for socket in sockets

io.on "connection", (socket) ->
  sockets.push socket

  socket.on "disconnect", ->
    sockets.splice sockets.indexOf(socket), 1

# User pages
app.get "/", (req, res) -> res.render "index", prod: PROD

# API routes
app.get "/example", (req, res) ->
  res.send "Hello World!"

server.listen process.env.PORT || 3000, "0.0.0.0", ->
  addr = server.address()
  console.log "Server listening at #{addr.address}:#{addr.port}"
