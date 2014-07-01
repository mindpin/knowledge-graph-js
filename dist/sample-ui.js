// Generated by CoffeeScript 1.7.1
(function() {
  seajs.config({
    base: './js/',
    alias: {
      'd3': 'lib/d3-3.4.6.min'
    },
    paths: {
      'graph': 'graph/dist'
    }
  });

  seajs.use('graph/view', function(KnowledgeView) {
    return jQuery(function() {
      if (jQuery('body.sample').length) {
        jQuery.getJSON('data/js/cook-pan.json', function(data) {
          return new KnowledgeView(jQuery('.graph-paper'), data);
        });
      }
      if (jQuery('body.sample-new-js').length) {
        return jQuery.getJSON('data/js/new-js.json', function(data) {
          return new KnowledgeView(jQuery('.graph-paper'), data);
        });
      }
    });
  });

}).call(this);

//# sourceMappingURL=sample-ui.map
