
zlib = require 'zlib'
http = require 'http'
{EventEmitter} = require 'events'

ALPHANUM_RADIX = 36

class StorageCollection
  constructor: (@cls, @alphaNum = false, @dense = true) ->
    @nextId = 1
    if @dense
      @data = []
    else
      @data = {}

  create: (base) ->
    obj = new @cls(base)
    @add(obj)
    obj

  indexToId: (index) ->
    if @alphaNum
      index.toString ALPHANUM_RADIX
    else
      index

  idToIndex: (id) ->
    if @alphaNum
      parseInt id, ALPHANUM_RADIX
    else

  add: (obj) ->
    index = @nextId++
    @data[index] = obj
    obj.id = @indexToId index

  get: (id) ->
    @data[@idToIndex id]

class Model
  constructor: (base) ->
    for k, v of base
      this[k] = v

class Interceptor extends Model
  updateExchange: (exchange) ->
    @transcriptEmitter.emit 'update', exchange

  addExchange: (exchange) ->
    @transcript.unshift(exchange)
    @transcriptEmitter.emit 'prepend', exchange

  constructor: (base) ->
    @transcript = []
    @transcriptEmitter = new EventEmitter()

    super(base)

class Exchange extends Model
  constructor: (base) ->
    @method = null
    @responseStatus = null
    @path = null
    super(base)

  getRequestData: ->
    models.files.get @requestData

  getResponseData: ->
    models.files.get @responseData

  reasonPhrase: ->
    http.STATUS_CODES[@responseStatus]

class StreamingFile extends Model
  constructor: ({@contentType,
                 @contentEncoding,
                 @contentLength,
                 @fileName}) ->
    @chunks = []
    @lenProcessed = 0
    @status = 'open'

  getContentType: ->
    @contentType?.split(';')[0]

  write: (data) =>
    @chunks.push(data)
    @lenProcessed += data.length

  err: (@error) ->
    console.log("Error: #{@error}")

  end: =>
    if @contentLength? and @lenProcessed.toString() != @contentLength
      @status = 'error'
      @err("Bad content length (expected #{@contentLength} bytes, got #{@lenProcessed})")
    else if @lenProcessed == 0
      @status = 'no data'
      @data = ''
    else
      @rawData = new Buffer(@lenProcessed)
      i = 0
      for chunk in @chunks
        chunk.copy @rawData, i, 0, chunk.length
        i += chunk.length

      if @contentEncoding == 'gzip'
        zlib.gunzip @rawData, (err, data) =>
          if err
            @status = 'error'
            @err(err)
          else
            @status = 'done'
            @data = data
      else
        @status = 'done'
        @data = @rawData

module.exports = models =
  interceptors: new StorageCollection(Interceptor, true, true)
  exchanges: new StorageCollection(Exchange, true, true)
  files: new StorageCollection(StreamingFile, true, true)

