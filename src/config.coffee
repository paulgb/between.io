
configOptions = (service) ->
  ALL = [
    'CLIENT_HTTP'
    'CLIENT_HTTPS'
    'PROXY_HTTP'
    'PROXY_HTTPS'
  ]
  CLIENT = [
    'CLIENT_HTTP'
    'CLIENT_HTTPS'
  ]
  HTTPS = [
    'CLIENT_HTTPS'
    'PROXY_HTTPS'
  ]

  'port':
    env: "#{service}_PORT"
    req: ALL
  'tls':
    env: "#{service}_TLS"
    default: 'false'
  'client hostname':
    env: 'WEB_HOSTNAME'
    req: CLIENT
  'proxy hostname':
    env: 'PROXY_HOSTNAME'
    req: CLIENT
  'tls private key':
    env: 'TLS_PRIVATE_KEY'
    req: HTTPS
  'tls certificate':
    env: 'TLS_CERTIFICATE'
    req: HTTPS
  'tls intermediate':
    env: 'TLS_INTERMEDIATE'
    req: HTTPS
  'dailycred client id':
    env: 'DAILYCRED_CLIENT_ID'
    req: CLIENT
  'dailycred secret':
    env: 'DAILYCRED_SECRET'
    req: CLIENT
  'cookie secret':
    env: 'COOKIE_SECRET'
    req: CLIENT
  'session secret':
    env: 'SESSION_SECRET'
    req: CLIENT
  'mongodb host':
    env: 'MONGODB_HOST'
    req: ALL
    default: 'mongodb://localhost/between'
  'id bunch size':
    env: 'ID BUNCH SIZE'
    req: ALL
    default: 10
  'id min allocated':
    env: 'ID MIN ALLOCATED'
    req: ALL
    default: 5

module.exports.configFromEnv = (app, service) ->
  console.log "Configuring app as #{service}"
  options = configOptions(service)
  for param, paramMeta of options
    if process.env[paramMeta.env]?
      value = process.env[paramMeta.env]
      source = 'environment variable'
    else if paramMeta.default?
      value = paramMeta.default
      source = 'default'
    else if service in paramMeta.req
      console.log "Required config param '#{param}' not found " +
        "(set environment variable #{paramMeta.env}"
      process.exit(1)
      
    console.log "Setting #{param} from #{source} to #{value}"
    app.set param, value

