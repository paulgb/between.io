
###
models.coffee contains the model code used by both the web app
and the proxy.
###

zlib = require 'zlib'
http = require 'http'
{EventEmitter} = require 'events'
mongoose = require 'mongoose'
{Schema, Types} = mongoose
{Mixed} = Types
{Mixed} = Schema.Types

ALPHANUM_RADIX = 36

module.exports = (app) ->
  ###
  The module exports a single function which, given the app,
  returns an object with all the models. This way the
  database configuration can be specified in the app object.
  ###
  
  # Connect to database
  db = mongoose.connect app.get('mongodb host'), (err) ->
    if err?
      console.log "DB Error: #{err}"
    else
      console.log "DB Connection Opened"
  
  ###
  between.io uses short alphanumeric IDs for most models. In
  order to ensure they are unique, we use a model called
  IdAllocatorMeta which stores the highest ID that has been
  reserved. Rather than checking with the database before
  assigning every single ID, each server process pre-allocates
  a configuratble number of IDs on start up and whenever the
  number pre-allocated dips below a certain number (due to
  allocation).
  ###
  
  idAllocatorMetaSchema = new Schema
    _id: String
    maxAllocated: {type: Number, default: 0}

  IdAllocatorMeta = db.model 'IdAllocatorMeta', idAllocatorMetaSchema

  class IdAllocator
    constructor: ->
      @bunchSize = parseInt(app.get 'id bunch size')
      @minAllocated = parseInt(app.get 'id min allocated')
      @namespace = 'main'
      @allocated = []
      @preAllocate()
    
    preAllocate: =>
      IdAllocatorMeta.findOneAndUpdate {_id: @namespace},
        {$inc: {maxAllocated: @bunchSize}},
        {upsert: true, new: false},
        (err, allocatorMeta) =>
          if err?
              console.log "Allocation error! #{err}"
              return
          console.log allocatorMeta
          start = allocatorMeta.maxAllocated
          end = allocatorMeta.maxAllocated + @bunchSize
          @allocated = @allocated.concat([start...end])

    take: =>
      if @allocated.length <= @minAllocated
        process.nextTick @preAllocate
      r = @allocated.shift().toString(ALPHANUM_RADIX)
      console.log "Giving ID #{r}"
      r

  idAllocator = new IdAllocator()

  interceptorSchema = new Schema
    _id: String
    host: String
    httpPort: Number
    httpsPort: Number
    user: String

  interceptorSchema.methods.getProxyHost = ->
    "#{@_id}.#{app.get 'proxy hostname'}"

  exchangePipeSchema = new Schema
    exchange: {type: String, ref: 'Exchange'}
    interceptor: {type: String, ref: 'Interceptor'}
    ,
      capped:
        size: 1024
        autoIndexId: false

  ExchangePipe = db.model 'ExchangePipe', exchangePipeSchema
  # dummy exchange to mitigate bug where mongo kills tailable
  # connections to empty capped collections
  new ExchangePipe().save()

  exchangeSchema = new Schema
    _id: String
    method: String
    path: String
    host: String
    requestHeaders: Mixed
    requestData: {type: String, ref: 'File'}
    responseHeaders: Mixed
    responseStatus: type: String
    responseData: {type: String, ref: 'File'}
    interceptor: {type: String, ref: 'Interceptor'}
    user: String

  exchangeSchema.methods.reasonPhrase = ->
    http.STATUS_CODES[@responseStatus]

  exchangeSchema.post 'save', ->
    new ExchangePipe(
      exchange: @_id
      interceptor: @interceptor
    ).save()

  fileSchema = new Schema
    _id: String
    contentType: String
    contentEncoding: String
    contentLength: Number
    fileName: String
    data: Buffer
    user: String

  return {
    Interceptor: db.model 'Interceptor', interceptorSchema
    Exchange: db.model 'Exchange', exchangeSchema
    File: db.model 'File', fileSchema
    ExchangePipe
    idAllocator
  }
    

