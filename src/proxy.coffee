
httpProxy = require 'http-proxy'

exports.ProxyServer = class ProxyServer
  # Class representing an HTTP proxy, instrumented with 
  # hooks to capture and modify the request and response
  # before they are forwarded. The constructor takes 
  # a class as an argument that is constructed for each
  # request and recieves the following callbacks:
  #
  #   getTarget(req)
  #     given the request object, return an Object
  #     with attributes {host, port, https} of the server
  #     to target
  #   onRequestWriteHead(method, path, headers)
  #     called when the request headers are available
  #   onRquestData(data)
  #     called when a chunk of request data is sent
  #   onRequestEnd()
  #     called when the client is finished sending
  #     the request
  #   onResponseWriteHead(statusCode, headers)
  #     called when the server has responded with
  #     headers
  #   onResponseWrite(data)
  #     called when the server sends a chunk of data
  #   onResponseEnd()
  #     called when the server ends the connection
  constructor: (cls, server) ->
    handleRequest = (server) => (req, res, proxy) =>
      exchange = new cls()

      requestDataBuffer = []
      requestEnded = false
      req.on 'data', (chunk) ->
        requestDataBuffer.push(chunk)
      req.on 'end', ->
        requestEnded = true

      exchange.getTarget req, server, (err, target) =>
        if err
          console.log "Error: #{err}"
          res.writeHead(404)
          res.end()
          return

        exchange.onRequestWriteHead? req.method, req.url, req.headers

        res._oldEnd = res.end
        res.end = =>
          exchange.onResponseEnd?()
          res._oldEnd()

        res._oldWrite = res.write
        res.write = (chunk) =>
          exchange.onResponseWrite? chunk
          res._oldWrite chunk

        res._oldWriteHead = res.writeHead
        res.writeHead = (statusCode, headers) =>
          exchange.onResponseWriteHead? statusCode, headers
          res._oldWriteHead statusCode, headers
        
        req.on 'data', (chunk) ->
          if exchange.onRequestWrite
            exchange.onRequestWrite(chunk)

        req.on 'end', ->
          if exchange.onRequestEnd
            exchange.onRequestEnd()

        proxy.proxyRequest req, res, target

        for chunk of requestDataBuffer
          req.emit 'data', chunk

        if requestEnded
          req.emit 'end'


    console.log "Starting proxy server"
    proxy = httpProxy.createServer handleRequest(server), server
    proxy.listen server.port, ->
      console.log "Proxy listening on port #{server.port}"
      
