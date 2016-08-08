# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

class ActiveSupport::TestCase
  def log_user(login, password)
    User.anonymous
    get '/login'
    assert_equal nil, session[:user_id]
    assert_response :success
    assert_template 'account/login'
    post '/login', username: login, password: password
    assert_equal login, User.find(session[:user_id]).login
  end

  def setup_wiki_page_with_tags(test_tags)
    public_project = Project.find(1)

    Wiki.create!(project_id: public_project.id, start_page: 'test_page')
    public_project.reload

    public_project.wiki.pages << WikiPage.new(title: 'some_wiki_page')
    page = public_project.wiki.pages.first
    page.tags_to_update = test_tags
    page.content = WikiContent.new(text: 'content')
    page.save!
    page
  end
end
