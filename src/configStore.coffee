
###
configStore.coffee is a (very) barebones configuration
store with an interface (superficially) similar to
Express's configuration management. It allows
config.coffee to be used by both the web app (an
Express app) and the proxy (which is not)
###

module.exports.ConfigStore = class ConfigStore
  set: (key, value) =>
    this[key] = value

  get: (key) =>
    this[key]

