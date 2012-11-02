
function listenTranscript(transcriptId) {
  transcript = {
    exchanges: ko.observableArray()
  };

  var exchangeMap = {};

  ko.applyBindings(transcript);

  var socket = io.connect();

  console.log('connecting');
  socket.on('connect', function() {
    console.log('connected');
    socket.emit('subscribe', transcriptId);
  });

  socket.on('transcript', function(exchanges) {
    console.log('got transcript, '+exchanges.length+' exchanges');
    for(i = 0; i < exchanges.length; i++) {
      var exchange = exchanges[i];
      var observableExchange = ko.observable(exchange);
      exchangeMap[exchange.id] = observableExchange;
      transcript.exchanges.push(observableExchange);
    }
    console.log('done pushing transcript');
  });

  socket.on('update', function(exchange) {
    var observableExchange = exchangeMap[exchange.id];
    observableExchange(exchange);
  });

  socket.on('exchange', function(exchange) {
    var observableExchange = ko.observable(exchange);
    transcript.exchanges.unshift(observableExchange);
    exchangeMap[exchange.id] = observableExchange;
  });

}

