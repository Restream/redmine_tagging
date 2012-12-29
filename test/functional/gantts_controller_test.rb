require File.dirname(__FILE__) + '/../test_helper'

class GanttsControllerTest < ActionController::TestCase
  fixtures :projects, :issues, :users, :trackers

  def setup
    @request.session[:user_id] = 2
    User.stubs(:current).returns(User.find_by_id(2))
    User.any_instance.stubs(:allowed_to?).returns(true)
    Mailer.stubs(:deliver_mail).returns(true)
    @some_tags = "#1, #2, #3,#4,#5"
    @issue_with_tags = setup_issue_with_tags(@some_tags)
    @project_with_tags = @issue_with_tags.project
  end

  def test_can_show_gantt
    get :show, :project_id => @project_with_tags.id
    assert_response :success
  end
end
