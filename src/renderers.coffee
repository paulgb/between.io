
jade = require('jade')
highlight = require('highlight.js')

contentTypes = require('./contentTypes')

class Renderer
  render: (file) ->
    @renderTemplate({file: file, data: file.data})

  get: (file) ->
    name: @name
    content: @render(file)

  canRender: (contentType) ->
    contentTypes.matchType(contentType, @contentTypes)

class RawRenderer extends Renderer
  name: 'plaintext'
  contentTypes: contentTypes.plaintextTypes
  renderTemplate: jade.compile('pre= data')

class ImageRenderer extends Renderer
  name: 'image'
  contentTypes: contentTypes.imageTypes
  renderTemplate: jade.compile '''
    img(src='/image/#{file.id}/#{file.fileName}')
    '''
class SyntaxRenderer extends Renderer
  name: 'syntax'

  typeMappings: contentTypes.typeMappings
  contentTypes: (type for type of contentTypes.typeMappings)

  renderTemplate: jade.compile('pre!= data')
  
  render: (file) ->
    highlighted = highlight.highlightAuto(file.data.toString('ascii'))
    @renderTemplate({data: highlighted.value})

class DownloadRenderer extends Renderer
  name: 'info'

  canRender: -> true

  renderTemplate: jade.compile(
    '''
    table(class='table table-bordered')
      tr
        th(style='width: 180px;') Type
        td= file.contentType
      tr
        th Size
        td= file.data.length
      tr
        th Raw Size
        td= file.rawData.length
      tr
        th Download
        td
          a(href='/file/#{file.id}/#{file.fileName}') Download
    ''')

  render: (file) ->
    @renderTemplate({file: file})

module.exports = class RenderManager
  constructor: ->
    @renderers = [
      new ImageRenderer()
      new SyntaxRenderer()
      new RawRenderer()
      new DownloadRenderer()
    ]

  render: (file) =>
    if not file.data?
      return []
    if file.data.length == 0
      return []
    renders = []
    for renderer in @renderers
      if renderer.canRender(file.contentType)
        renders.push renderer.get(file)
    return renders

