
###
contentTypes.coffee adds some intellegence around
MIME content types.
###

module.exports =
  
  # types that make sense to serve as raw text
  plaintextTypes: [
    /^text/
    /^application\/(x-)?javascript/
    /^image\/svg\+xml/
    /^application\/xml/
    /^application\/json/
    /^application\/x-www-form-urlencoded/
  ]

  # types that make sense to serve as images
  imageTypes: [
    /^image\//
  ]

  # match every type
  allTypes: [
    /./
  ]

  # map MIME types to highlight.js highlighters
  typeMappings:
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

  matchType: (contentType, contentTypes) ->
    ###
    Given a contentType string and a list of
    contentTypes (which may be strings or
    regular expressions), return true if
    one of the contentTypes matches the
    given content type.
    ###
    for typeMatch in contentTypes
      if typeof(typeMatch) == 'string'
        if contentType == typeMatch
          return true
      else if typeMatch.test(contentType)
        return true
    return false

