
class Renderer
  render: (file) ->
    @renderTemplate({file: file, data: file.data})

  get: (file) ->
    name: @name
    content: @render(file)

  canRender: (contentType) ->
    for typeMatch in @contentTypes
      if typeof(typeMatch) == 'string'
        if contentType == typeMatch
          return true
      else if typeMatch.test(contentType)
        return true
    return false

class RawRenderer extends Renderer
  name: 'plaintext'
  contentTypes: [
    /^text/
    /^application\/(x-)?javascript/
    /^image\/svg\+xml/
    /^application\/xml/
    /^application\/json/
    /^application\/x-www-form-urlencoded/
  ]
  renderTemplate: jade.compile('pre= data')

class SyntaxRenderer extends Renderer
  name: 'syntax'

  typeMappings =
    'application/x-ruby': 'ruby'
    'application/x-python': 'python'
    'application/json': 'json'
    'text/css': 'css'
    'application/xml': 'xml'
    'text/html': 'xml'
    'image/svg+xml': 'xml'
    'text/x-haskell': 'haskell'
    'text/x-perl': 'perl'
    'application/x-httpd-php': 'php'
    'text/javascript': 'javascript'
    'application/javascript': 'javascript'
    'application/x-javascript': 'javascript'

  typeMappings: typeMappings
  contentTypes: (type for type of typeMappings)

  renderTemplate: jade.compile('pre!= data')
  
  render: (file) ->
    highlighted = highlight.highlightAuto(file.data.toString('ascii'))
    @renderTemplate({data: highlighted.value})

class DownloadRenderer extends Renderer
  name: 'info'

  contentTypes: [
    /./
  ]

  renderTemplate: jade.compile(
    '''
    table(class='table table-bordered')
      tr
        th(style='width: 180px;') Type
        td= file.contentType
      tr
        th Size
        td= filesize(file.data.length)
      tr
        th Raw Size
        td= filesize(file.rawData.length)
      tr
        th Download
        td
          a(href='#') Download
    ''')

  render: (file) ->
    console.log file
    @renderTemplate({file: file, filesize})

class RenderManager
  constructor: ->
    @renderers = [
      #new SyntaxRenderer()
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
