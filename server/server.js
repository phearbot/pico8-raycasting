'use strict';

const ws = require('ws');
const server = new ws.Server({port: 8080});

// This variable should match netcode.js
var OUTPUT_SIZE = 16;
var connectingPlayers = [];
var disconnectingPlayers = [];

server.on('connection', (connection) => 
{
	connection.id = getUniqueID();
	connection.playerData = new Uint8Array(OUTPUT_SIZE);
	connection.hasNewData = false;
	connection.clientLoadState = 0; // 0=web socket connected, 1=client loaded, 2=playing
	

	console.log('Client ' + connection.id + ' connected');
	// connection.send('test');

	// When data is being received
	connection.on('message', (data) =>
	{
		// Don't actually send the data the first time, otherwise people get input for a player that isn't added
		if (connection.clientLoadState == 0){
			connection.clientLoadState++;
			connectingPlayers.push(connection.id);
			console.log('Client ' + connection.id + ' loaded (first message received)');
		} else {
			console.log('Client message received.');
			connection.playerData = data;
			connection.hasNewData = true;
		}
  	}); 

  	// When connection is closed
  	connection.on('close', (data) =>
	{
		disconnectingPlayers.push(connection.id);
		console.log('Client ' + connection.id + ' disconnected');
  	}); 

  	//Debugging trying to understand the objects
 //  	server.clients.forEach((client) =>
	// {
 //    	console.log("ID: " + client.id);
 //  	});
});

var SENDING_FREQUENCY = 1000/60
setInterval(function()
{
	// outer loop iterates over clients being sent to for movement and new players
	// (this is probably not very effective as the looping grows exponentially)
	server.clients.forEach((client) =>
	{
		var dataToSend = new Uint8Array(128 - OUTPUT_SIZE);
		var currentIndex = 0;

		// Only runs if a client has disconnected
		for (var i = 0; i < disconnectingPlayers.length; i++) {
			dataToSend[currentIndex++] = 3; // 3 is the ID for removing a player
			dataToSend[currentIndex++] = disconnectingPlayers[i];
		}


		// Only runs if THIS client is a new player (adds all other players)
		if (client.clientLoadState == 1) {
			server.clients.forEach((subclient) => {
				if (client.id != subclient.id && subclient.clientLoadState > 0) {
					dataToSend[currentIndex++] = 1; // 1 is the ID for adding a new player
					dataToSend[currentIndex++] = subclient.id; 
					for (var i = 0; i < 12; i++)
						dataToSend[currentIndex++] = subclient.playerData[i];

					console.log('Added client ' + subclient.id + ' to client ' + client.id);
				}
		    //console.log("ID: " + client.id);
		  	});

		  	client.clientLoadState++;
		}


		// inner loop is looking for data that needs to be appended from players with new data
		server.clients.forEach((subclient) => {
			// Only runs if players have connected (adds new player to all players)
			for (var i = 0; i < connectingPlayers.length; i++) {
				if (connectingPlayers[i] == subclient.id && client.id != subclient.id) {
					dataToSend[currentIndex++] = 1; // 1 is the ID for adding a new player
					dataToSend[currentIndex++] = subclient.id; 
					for (var i = 0; i < 12; i++) {
						dataToSend[currentIndex++] = subclient.playerData[i];
					}

					console.log('Adding client ' + subclient.id + ' to client ' + client.id);
				}	
			}

			// If any players have moved, add their data.
			if (subclient.hasNewData && subclient.id != client.id)
			{
				dataToSend[currentIndex++] = 2; // 2 is the ID for moving a player
				dataToSend[currentIndex++] = subclient.id; 
				for (var i = 0; i < 12; i++) {
					dataToSend[currentIndex++] = subclient.playerData[i];
				}
			}

		});

	// Send the data built in the loop above if there is data
	if (currentIndex > 0) 
		client.send(JSON.stringify(dataToSend));

	// if (client.clientLoadState == 1)
	// 	client.clientLoadState++;

	});


	// Once all input has been accounted for on all clients, flag is reset
	server.clients.forEach((client) =>
	{
		client.hasNewData = false
	});

	connectingPlayers = []; // this isn't done in the loop so all players will get the new player
	disconnectingPlayers = [];
}, SENDING_FREQUENCY);

// function loadAllPlayers(newClient) {
//   	server.clients.forEach((oldClient) => {
//   		// You can assume the index starts at 0 because this runs prior to the rest
  		
//     	console.log("ID: " + client.id);
//   	});
// }


// previously used https://stackoverflow.com/questions/13364243/websocketserver-node-js-how-to-differentiate-clients
// this current solution will break after 256 total players have joined in the lifetime of the server.  
var nextId = 0
function getUniqueID() {
    return nextId++;
};

console.log('Listening for connections');