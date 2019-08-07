// adapted from https://neopolita.itch.io/pico8com/

var pico8_gpio = Array(128);

// Connection

var connection = new WebSocket('ws://127.0.0.1:8080');
//var connection = new WebSocket('ws://planeteightgames.com:8080');
connection.onopen = function() 
{
	console.log('Connected to server');
};

connection.onerror = function(error) 
{
	console.log('Connection error ' + error);
};

connection.onmessage = function(event) 
{
	var data = event.data;
	console.log('Server message ' + data + ' received');

	processInput(data);
};

// Output
var OUTPUT_INDEX = 0;
var OUTPUT_SIZE = 16;
var OUTPUT_FREQUENCY = 1000 / 60;

var outputData = new Uint8Array(OUTPUT_SIZE);
var previousOutput = new Uint8Array(OUTPUT_SIZE);

setInterval(function()
{
	var sendData = false
	outputData = new Uint8Array(OUTPUT_SIZE);
	for (var i = OUTPUT_INDEX; i < OUTPUT_SIZE; i ++)
	{
		outputData[i] = pico8_gpio[i];
		if (outputData[i] != previousOutput[i])
			sendData = true;
	}

	// Only send output if there has been a change since last frame
	if (sendData)
	{
		processOutput();
		// console.log(outputMessage);
		console.log(outputData)
	}

	previousOutput = outputData;
}, OUTPUT_FREQUENCY);

// This likely could just be a single line in the other function
function processOutput()
{
	connection.send(outputData);
}

// Input (Input from the server to the client -- not to be confused with player input)
var INPUT_INDEX = OUTPUT_INDEX + OUTPUT_SIZE;
var INPUT_SIZE = 128 - OUTPUT_SIZE;
var INPUT_FREQUENCY = 1000 / 60; // reducing this may help with variable latency/jitter?

var inputQueue = [];
var inputMessage = null;


function processInput(message)
{
	console.log('processInput() called!');
	inputQueue.push(message);
}

setInterval(function()
{
	// var control = pico8_gpio[INPUT_INDEX];
	// if (control == 1) return;


	if (inputMessage == null && inputQueue.length > 0)
	 	inputMessage = JSON.parse(inputQueue.shift());

	if (inputMessage != null)
	{
		console.log('received: ' + inputMessage);
		pico8_gpio[INPUT_INDEX] = 1;
		for (var i = INPUT_INDEX; i < 128; i ++) {
			pico8_gpio[i] = inputMessage[i - INPUT_INDEX];
		}

		console.log('pico8_gpio: ' + pico8_gpio)

		inputMessage = null;


		// var chunk = inputMessage.substr(0, 63);
		// for (var i = 0; i < chunk.length; i ++)
		// 	pico8_gpio[INPUT_INDEX + 1 + i] = chunk.charCodeAt(i);

		// inputMessage = inputMessage.substr(63);
		// if (inputMessage.length == 0)			
		// {
		// 	inputMessage = null;
		// 	if (chunk.length == 63)
		// 		pico8_gpio[INPUT_INDEX] = 2;
		// }	
	}
}, INPUT_FREQUENCY);













