http = require 'http'
express = require 'express'
{ spawn } = require 'child_process'
WebSocketServer = require('ws').Server

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
	# '-loglevel', 'quiet'
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
	if currentSocket isnt null
		try
			console.log(chunk.length)
			currentSocket.send(chunk, binary: true)
		catch e
			console.log(e)

app.post '/die', (req, res) ->
	server.close ->
		res.send('OK')

server.on('request', app)

http.request { method: 'POST', path: '/die' }, ->
	server.listen(80)
.on 'error', (e) ->
	console.log('ignored error', e)
	server.listen(80)
