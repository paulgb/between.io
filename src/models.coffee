
zlib = require 'zlib'
http = require 'http'
{EventEmitter} = require 'events'
mongoose = require 'mongoose'
{Schema, Types} = mongoose
{Mixed} = Types
{Mixed} = Schema.Types

db = mongoose.createConnection 'localhost', 'test'
db.once 'open', ->
  console.log 'DB Connection Opened'

interceptorSchema = new Schema
  host: String

exchangePipeSchema = new Schema
  exchange: {type: Schema.Types.ObjectId, ref: 'Exchange'}
  interceptor: {type: Schema.Types.ObjectId, ref: 'Interceptor'}
  ,
    capped:
      size: 1024
      autoIndexId: false

ExchangePipe = db.model 'ExchangePipe', exchangePipeSchema

exchangeSchema = new Schema
  method: String
  path: String
  host: String
  requestHeaders: Mixed
  requestData: {type: Schema.Types.ObjectId, ref: 'File'}
  responseHeaders: {type: Mixed, default: {}}
  responseStatus: {type: String, default: null}
  responseData: {type: Schema.Types.ObjectId, ref: 'File'}
  interceptor: {type: Schema.Types.ObjectId, ref: 'Interceptor'}

exchangeSchema.methods.reasonPhrase = ->
  http.STATUS_CODES[@responseStatus]

exchangeSchema.post 'save', ->
  new ExchangePipe(
    exchange: @_id
    interceptor: @interceptor
  ).save()

fileSchema = new Schema
  contentType: String
  contentEncoding: String
  contentLength: Number
  fileName: String
  data: Buffer

module.exports =
  Interceptor: db.model 'Interceptor', interceptorSchema
  Exchange: db.model 'Exchange', exchangeSchema
  File: db.model 'File', fileSchema
  ExchangePipe: ExchangePipe
  

