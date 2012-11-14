
###
fileBuffer.coffee contains the code responsable for
buffering the request/response body data until it is
all recieved.
###

{EventEmitter} = require 'events'
zlib = require 'zlib'

class FileBuffer extends EventEmitter
  ###
  The FileBuffer stores a bunch of chunks of data
  (through the `write` method) until the `end` method
  is called, at which point it combines the data
  (and decompresses it as needed) and emits the
  `data` event with the data.
  ###
  
  constructor: (@contentLength, @contentEncoding) ->
    # contentLength is used to verify length of data
    # contentEncoding is used to determine whether
    #   decompression is needed
    @chunks = []
    @lenProcessed = 0

  write: (data) =>
    ###
    Add a chunk of data. `data` is a buffer or a string
    ###
    @chunks.push(data)
    @lenProcessed += data.length

  end: =>
    ###
    Done sending data. Combine the existing data and emit
    the `data` event.
    ###
    if @contentLength? and @lenProcessed.toString() != @contentLength
      @emit('error', "Bad content length (expected #{@contentLength} bytes, got #{@lenProcessed})")
    else
      rawData = new Buffer(@lenProcessed)
      i = 0
      for chunk in @chunks
        chunk.copy rawData, i, 0, chunk.length
        i += chunk.length

      if @contentEncoding == 'gzip'
        zlib.gunzip rawData, (err, data) =>
          if err
            console.log 'gzip error'
            @emit('error', "gzip error #{err}")
          else
            @emit('data', data)
      else
        @emit('data', rawData)

module.exports = {FileBuffer}

