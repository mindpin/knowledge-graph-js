seajs.config
  base: './js/'
  alias:
    'd3': 'lib/d3-3.4.6.min'
  paths:
    'graph': 'graph/dist'

seajs.use 'graph/view', (KnowledgeView)->
  jQuery ->
    if jQuery('body.sample').length
      jQuery.getJSON 'js/graph/fixture/art313.json', (data)->
      # jQuery.getJSON 'data/js/js.json', (data)->
        new KnowledgeView jQuery('.graph-paper'), data

    if jQuery('body.sample-new-js').length
      jQuery.getJSON 'data/js/new-js.json', (data)->
        new KnowledgeView jQuery('.graph-paper'), data