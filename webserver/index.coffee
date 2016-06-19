http = require 'http'
express = require 'express'
{ spawn } = require 'child_process'
WebSocketServer = require('ws').Server

THERMAL_CAMERA = 0

server = http.createServer()
wss = new WebSocketServer(server: server)

app = express()
app.use(express.static('public'))

STREAM_MAGIC_BYTES = 'jsmp'

ffmpegParams = [
	'-s', '80x60'
	'-f', 'video4linux2'
	'-i', '/dev/video0'
	'-f', 'mpeg1video'
	'-r', '24'
	'-loglevel', 'error'
	'-'
]

ffmpeg = spawn('ffmpeg', ffmpegParams)

ffmpeg.stdout.resume()

ffmpeg.stderr.pipe(process.stderr)

width = 80
height = 60

currentSocket = null

wss.on 'connection', (socket) ->
	currentSocket = socket

	streamHeader = new Buffer(8)
	streamHeader.write(STREAM_MAGIC_BYTES)
	streamHeader.writeUInt16BE(width, 4)
	streamHeader.writeUInt16BE(height, 6)

	console.log('sending mpeg header')
	socket.send(streamHeader, binary:true)

ffmpeg.stdout.on 'data', (chunk) ->
	if currentSocket isnt null and THERMAL_CAMERA
		try
			currentSocket.send(chunk, binary: true)
		catch e
			# console.log(e)

app.post '/die', (req, res) ->
	ffmpeg.kill('SIGTERM')
	ffmpeg.on 'exit', ->
		currentSocket.close()
		res.end('OK')
		server.close()

server.on('request', app)

req = http.request { method: 'POST', path: '/die' }, (res) ->
	res.resume()
	res.on 'end', ->
		server.listen(80)
.on 'error', (e) ->
	console.log('ignored error', e)
	server.listen(80)

req.end()
