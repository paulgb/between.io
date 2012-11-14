
###
dispatch.coffee is the CoffeeScript entry point. It
looks at the first command-line argument and requires
either the proxy or client code accordingly. Note
that HTTP and HTTPS are considered separate types of
servers and exist in separate processes. Because we
have a share-nothing architecture, this is fine.
###

main = ->
  if not process.argv[2]?
    console.log 'Server class expected on command line'
    console.log 'eg. node app.js CLIENT_HTTP'
    process.exit 1

  serverClass = process.argv[2]

  if serverClass in ['CLIENT_HTTP', 'CLIENT_HTTPS']
    require('./clientServer').run serverClass
  else if serverClass in ['PROXY_HTTP', 'PROXY_HTTPS']
    require('./proxyServer').run serverClass
  else
    console.log "Invalid server type #{serverClass}"
    process.exit 1

main()
