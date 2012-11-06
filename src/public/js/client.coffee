
metaDispatch =
  'attach-transcript': require('./transcript').listenTranscript

$ ->
  $('meta').each (i, el) ->
    if metaDispatch[el.name]?
      metaDispatch[el.name](el.content)

