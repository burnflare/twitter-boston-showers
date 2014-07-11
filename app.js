var express = require('express');
var http = require('http');
var faye = require('faye');

var app = express();
var server = http.createServer(app);
var bayeux = new faye.NodeAdapter({mount: '/faye', timeout: 45});

app.use(express.static(__dirname + '/public'));

var port = 3000;
var utcOffset = 5;
var clientCount = 0;

var leftArr = [];
var rightArr = [];

function init(){
	var eSeconds = Math.floor(new Date() / 1000);
	leftArr.push({
		status: "unlock",
		time: eSeconds
	});
	rightArr.push({
		status: "unlock",
		time: eSeconds
	});
}

function canToggle(doorStatus, door) {
	if (door.length > 0) {
		var last = door[door.length -1];
		if (last.status != doorStatus) {
			return true;
		} else {
			return false;
		}
	}
	return true;
}

function switchDoorToStatus(doorStatus, door) {
	var eSeconds = Math.floor(new Date() / 1000);
	var arr;
	
	if (door == "left") {
		arr = leftArr;
	} else if(door == "right") {
		arr = rightArr;
	}
	
	if (canToggle(doorStatus, arr)) {
		arr.push({
			status: doorStatus,
			time: eSeconds
		})
	}
	broadcastToClients();
}

function broadcastToClients(){
	bayeux.getClient().publish('/showers', {
	  left:		leftArr,
	  right:  	rightArr
	});
}

// render index.html
app.get('/', function(req, res) {
	res.render('index.html');
});

// to monitor for updates from iOS client
bayeux.getClient().subscribe('/updates', function(message) {
	switchDoorToStatus(message.status, message.door);
});

// triger on new user
bayeux.bind('subscribe', function(clientId, chanell) {
	clientCount++;
	console.log('++ Current user count: ' + clientCount);
	setTimeout(broadcastToClients, 500)
});

// trigger when user leaves
bayeux.bind('unsubscribe', function(clientId, chanell) {
	clientCount--;
	console.log('-- Current user count: ' + clientCount);
});

init();

bayeux.attach(server);
server.listen(port, function () {
   console.log('Express server started on port %s', server.address().port);
});


var Twit = require('twit')

var T = new Twit({
    consumer_key:         'yLivYL28pkA0EuaGkKb9FkCuL'
  , consumer_secret:      'o64J1pV87pPIJidW2wIX66RPEGQmUOCQAfOQ9lZs5qY200P3uc'
  , access_token:         '2616504360-l3KjzCWgDIdbGrV0la6Ne5hLD9SJot6ntBMYkl2'
  , access_token_secret:  '1KiR6ILB2oUXpsO9FZqjlIKG5q3KQM13ffvW3Tj5kR00Q'
})

var stream = T.stream('statuses/filter', { track: '@bosshower' , replies: 'all'})

stream.on('tweet', function (tweet) {
	var user = tweet.user;
	var name = user.name;
	var screenName = user.screen_name;
	
	var message = '@' + screenName + ' Yo ' + name + '.\n#shower613 is ' + prettyTextForDoor(leftArr) + '.\n#shower612 is ' + prettyTextForDoor(rightArr) + '.\n\nYoyo peace out.';
	T.post('statuses/update', { status: message }, function(err, data, response) {
		if (err) {
			console.log(err);
		}
	})
})

function prettyTextForDoor(doorArr){
	var last = doorArr[doorArr.length -1];
	if (last.status == 'lock') {
		return 'currently in use';
	} else {
		return 'currently free';
	}
}

