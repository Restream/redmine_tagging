ActionController::Routing::Routes.draw do |map|
  map.resources :issue_tags, :only => [:destroy]
  map.resources :tagging, :only => [:index]
end
