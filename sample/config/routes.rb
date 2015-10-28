Rails.application.routes.draw do
  mount KnowledgeGraphJs::Engine => '/', :as => 'knowledge_graph_js'
  mount PlayAuth::Engine => '/auth', :as => :auth
end
