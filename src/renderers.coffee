
jade = require 'jade'
highlight = require 'highlight.js'
qs = require 'querystring'

contentTypes = require './contentTypes'

class Renderer
  render: (file) ->
    @renderTemplate({file: file, data: file.data})

  get: (file) ->
    name: @name
    content: @render(file)

  canRender: (contentType) ->
    contentTypes.matchType(contentType, @contentTypes)

class Linker extends Renderer
  get: (file) ->
    name: @name
    href: @link(file)

class RawLinker extends Linker
  name: 'raw'
  contentTypes: contentTypes.plaintextTypes
  link: (file) -> "/raw/#{file.id}/#{file.fileName}"

class DownloadLinker extends Linker
  name: 'download'
  contentTypes: contentTypes.allTypes
  link: (file) -> "/file/#{file.id}/#{file.fileName}"

class FormRenderer extends Renderer
  name: 'postdata'

  contentTypes: [
    'application/x-www-form-urlencoded'
  ]

  renderTemplate: jade.compile '''
    table(class='table table-headers')
      for val, key in keyvals
        tr
          th= key
          td= val
    '''

  render: (file) ->
    data = file.data.toString('ascii')
    keyvals = qs.parse(data)
    @renderTemplate({keyvals})

class RawRenderer extends Renderer
  name: 'plaintext'
  contentTypes: contentTypes.plaintextTypes
  renderTemplate: jade.compile '''
  pre
    code= data
  '''

class ImageRenderer extends Renderer
  name: 'image'
  contentTypes: contentTypes.imageTypes
  renderTemplate: jade.compile '''
    img(class='preview', src='/image/#{file.id}/#{file.fileName}')
    '''

class SyntaxRenderer extends Renderer
  name: 'syntax'

  typeMappings: contentTypes.typeMappings
  contentTypes: (type for type of contentTypes.typeMappings)

  renderTemplate: jade.compile '''
  pre
    code!= data'''
  
  render: (file) ->
    highlighted = highlight.highlightAuto(file.data.toString('ascii'))
    @renderTemplate({data: highlighted.value})

module.exports = class RenderManager
  constructor: ->
    @renderers = [
      new FormRenderer()
      new ImageRenderer()
      new SyntaxRenderer()
      new RawRenderer()
      new RawLinker()
      new DownloadLinker()
    ]

  render: (file) =>
    if not file.data? or file.data.length == 0
      return {
        renders: []
        links: []
      }
    renders = []
    links = []
    for renderer in @renderers
      if renderer.canRender(file.contentType.split(';')[0])
        result = renderer.get(file)
        if result.content?
          renders.push(result)
        if result.href?
          links.push(result)
    return {renders, links}

