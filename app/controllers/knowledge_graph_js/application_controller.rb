module KnowledgeGraphJs
  class ApplicationController < ActionController::Base
    layout "knowledge_graph_js/application"

    if defined? PlayAuth
      helper PlayAuth::SessionsHelper
    end
  end
end