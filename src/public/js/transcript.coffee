
module.exports.listenTranscript = (transcriptId) ->
  transcript =
    exchanges: ko.observableArray()

  exchangeMap = {}

  ko.applyBindings transcript

  socket = io.connect()

  console.log 'connecting'
  socket.on 'connect', ->
    console.log 'connected'
    socket.emit 'subscribe', transcriptId

  socket.on 'transcript', (exchanges) ->
    console.log "got transcript, #{exchanges.length} exchanges"
    for exchange in exchanges
      observableExchange = ko.observable exchange
      exchangeMap[exchange.id] = observableExchange
      transcript.exchanges.unshift observableExchange

    console.log 'done pushing transcript'

  socket.on 'update', (exchange) ->
    console.log exchange
    observableExchange = exchangeMap[exchange.id]
    observableExchange exchange

