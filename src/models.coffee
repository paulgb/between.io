
ALPHANUM_RADIX = 36

class StorageCollection
  constructor: (@cls, @alphaNum = false, @dense = true) ->
    @nextId = 1
    if @dense
      @data = []
    else
      @data = {}

  create: (base) ->
    obj = new @cls(base)
    @add(obj)
    obj

  indexToId: (index) ->
    if @alphaNum
      index.toString ALPHANUM_RADIX
    else
      index

  idToIndex: (id) ->
    if @alphaNum
      parseInt id, ALPHANUM_RADIX
    else

  add: (obj) ->
    index = @nextId++
    @data[index] = obj
    obj.id = @indexToId index

  get: (id) ->
    @data[@idToIndex id]

class Model
  constructor: (base) ->
    for k, v of base
      this[k] = v

class Interceptor extends Model
  constructor: (base) ->
    @transcript = []
    super(base)

class Exchange extends Model

module.exports = models =
  interceptors: new StorageCollection(Interceptor, true, true)
  exchanges: new StorageCollection(Exchange, true, true)

