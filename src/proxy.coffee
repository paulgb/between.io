
{ProxyServer} = require('./proxyServer')
{Interceptor} = require('./models')

class BetweenProxy extends ProxyServer
  getTarget: (req) ->
