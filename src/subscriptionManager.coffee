
class SubscriptionManager
  constructor: (@callback) ->
    @listeners = {}

  notify: (listenId, message) ->
    #console.log "Notify, #{listenId}"
    if not @listeners[listenId]?
      return
    for handlerId, handler of @listeners[listenId]
      @callback(message, handler)

  sub: (listenId, handlerId, handler) ->
    console.log "Subscribe request, #{listenId} -> #{handlerId}"
    if not @listeners[listenId]?
      @listeners[listenId] = {}
    @listeners[listenId][handlerId] = handler

  unsub: (listenId, handlerId) ->
    console.log "Remove request, #{listenId} -> #{handlerId}"
    delete @listeners[listenId][handlerId]
    if Object.keys(@listeners[listenId]).length == 0
      delete @listeners[listenId]

module.exports = {SubscriptionManager}

