
function listenTranscript(transcriptId) {
  transcript = {
    exchanges: ko.observableArray()
  };

  var exchangeMap = {};

  ko.applyBindings(transcript);

  var socket = io.connect();

  socket.on('connect', function() {
    socket.emit('subscribe', transcriptId);
  });

  socket.on('transcript', function(exchanges) {
    for(i = 0; i < exchanges.length; i++) {
      var exchange = exchanges[i];
      var observableExchange = ko.observable(exchange);
      exchangeMap[exchange.id] = observableExchange;
      transcript.exchanges.push(observableExchange);
    }
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

