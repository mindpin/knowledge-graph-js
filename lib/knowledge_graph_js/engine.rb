module KnowledgeGraphJs
  class Engine < ::Rails::Engine
    isolate_namespace KnowledgeGraphJs
    config.to_prepare do
      ApplicationController.helper ::ApplicationHelper
    end
  end
end