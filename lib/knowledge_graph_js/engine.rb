module KnowledgeGraphJs
  class Engine < ::Rails::Engine
    isolate_namespace KnowledgeGraphJs
    config.to_prepare do
      ApplicationController.helper ::ApplicationHelper
    end

    initializer 'knowledge-graph-js.assets.precompile' do |app|
      app.config.assets.paths << root.join('app/assets/fixture')

      app.config.assets.precompile << "knowledge_graph_js/graph/view.js"
      app.config.assets.precompile << "knowledge_graph_js/graph/net.js"
      app.config.assets.precompile << "knowledge_graph_js/graph/zoomer.js"
      app.config.assets.precompile << "knowledge_graph_js/graph/sample-ui.js"

      app.config.assets.precompile << "knowledge_graph_js/test.js"

      app.config.assets.precompile << "knowledge_graph_js/qunit/qunit-1.14.0.css"
    end

  end
end
