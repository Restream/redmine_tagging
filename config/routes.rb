ActionController::Routing::Routes.draw do |map|
  map.resources :issue_tags, :only => [:destroy]
end
