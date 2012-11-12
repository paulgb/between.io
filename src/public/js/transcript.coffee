
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

  socket.on 'error', (error) ->
    console.log "Error: #{error}"

  socket.on 'transcript', (exchanges) ->
    console.log "got transcript, #{exchanges.length} exchanges"
    for exchange in exchanges
      if exchangeMap[exchange._id]?
        observableExchange = exchangeMap[exchange._id]
        observableExchange exchange
      else
        observableExchange = ko.observable exchange
        exchangeMap[exchange._id] = observableExchange
        transcript.exchanges.unshift observableExchange

    console.log 'done pushing transcript'

