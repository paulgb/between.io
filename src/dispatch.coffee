
main = ->
  if not process.argv[2]?
    console.log 'Server class expected on command line'
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
