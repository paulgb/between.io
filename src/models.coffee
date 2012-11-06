
zlib = require 'zlib'
http = require 'http'
{EventEmitter} = require 'events'
mongoose = require 'mongoose'
{Schema, Types} = mongoose
{Buffer, Mixed} = Types
{Mixed} = Schema.Types

db = mongoose.createConnection 'localhost', 'test'
db.once 'open', ->
  console.log 'DB Connection Opened'

interceptorSchema = new Schema
  host: String

exchangeSchema = new Schema
  method: String
  path: String
  requestHeaders: Mixed
  requestData: Schema.Types.ObjectId
  responseHeaders: Mixed
  responseStatus: Number
  responseData: Schema.Types.ObjectId
  interceptor: Schema.Types.ObjectId

fileSchema = new Schema
  contentType: String
  contentEncoding: String
  contentLength: Number
  fileName: String
  data: [Buffer]

module.exports =
  Interceptor: db.model 'Interceptor', interceptorSchema
  Exchange: db.model 'Exchange', exchangeSchema
  File: db.model 'File', fileSchema

