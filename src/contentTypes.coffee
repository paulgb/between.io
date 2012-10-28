
module.exports =
  plaintextTypes: [
    /^text/
    /^application\/(x-)?javascript/
    /^image\/svg\+xml/
    /^application\/xml/
    /^application\/json/
    /^application\/x-www-form-urlencoded/
  ]

  imageTypes: [
    /^image\//
  ]

  allTypes: [
    /./
  ]

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
    for typeMatch in contentTypes
      if typeof(typeMatch) == 'string'
        if contentType == typeMatch
          return true
      else if typeMatch.test(contentType)
        return true
    return false

