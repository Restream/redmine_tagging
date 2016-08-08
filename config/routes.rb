RedmineApp::Application.routes.draw do
  resources :issue_tags, only: [:destroy]
end
