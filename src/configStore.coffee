
module.exports.ConfigStore = class ConfigStore
  set: (key, value) =>
    this[key] = value

  get: (key) =>
    this[key]

