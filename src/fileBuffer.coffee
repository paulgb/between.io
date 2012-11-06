
{EventEmitter} = require 'events'

class FileBuffer extends EventEmitter
  constructor: (@contentLength) ->
    @chunks = []
    @lenProcessed = 0

  write: (data) =>
    @chunks.push(data)
    @lenProcessed += data.length

  end: =>
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
            @emit('error', "gzip error #{err}")
          else
            @emit('data', data)
      else
        @emit('data', rawData)

module.exports = {FileBuffer}

