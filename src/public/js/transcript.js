
function listenTranscript(transcriptId) {
  transcript = {
    exchanges: ko.observableArray()
  };

  ko.applyBindings(transcript);

  var socket = io.connect();

  socket.on('connect', function() {
    socket.emit('subscribe', transcriptId);
  });

  socket.on('exchange', function(data) {
    console.log(data);
    transcript.exchanges.unshift(data);
  });
}

