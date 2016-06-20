var http = require('http');
var express = require('express');
var spawn = require('child_process').spawn;
var WebSocketServer = require('ws').Server;

var THERMAL_CAMERA = 0;
var WIDTH = 80;
var HEIGHT = 60;
var STREAM_MAGIC_BYTES = 'jsmp';

var server = http.createServer();

var wss = new WebSocketServer({ server: server });

var app = express();

app.use(express.static('public'));

var ffmpegParams = [
	'-s', WIDTH + 'x' + HEIGHT,
	'-f', 'video4linux2',
	'-i', '/dev/video0',
	'-f', 'mpeg1video',
	'-r', '24',
	'-loglevel', 'error',
	'-'
];

var ffmpeg = spawn('ffmpeg', ffmpegParams);

ffmpeg.stdout.resume();

ffmpeg.stderr.pipe(process.stderr);

var currentSocket = null;

wss.on('connection', function(socket) {
	var streamHeader;
	currentSocket = socket;

	streamHeader = new Buffer(8);
	streamHeader.write(STREAM_MAGIC_BYTES);
	streamHeader.writeUInt16BE(WIDTH, 4);
	streamHeader.writeUInt16BE(HEIGHT, 6);

	console.log('sending mpeg header');
	socket.send(streamHeader, { binary: true });
});

ffmpeg.stdout.on('data', function(chunk) {
	if (currentSocket !== null && THERMAL_CAMERA) {
		try {
			currentSocket.send(chunk, { binary: true });
		} catch {
			// ignore error
		}
	}
});

app.post('/die', function(req, res) {
	ffmpeg.kill('SIGTERM');

	ffmpeg.on('exit', function() {
		currentSocket.close();
		res.end('OK');
		server.close();
	});
});

server.on('request', app);

req = http.request({ method: 'POST', path: '/die' }, function(res) {
	res.resume();
	res.on('end', function() {
		server.listen(80);
	});
}).on('error', function(e) {
	console.log('Ignored handover error, listening anyway', e);
	server.listen(80);
});

req.end();
