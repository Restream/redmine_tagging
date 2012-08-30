require File.dirname(__FILE__) + '/../test_helper'

class IssueTagsControllerTest < ActionController::TestCase
  fixtures :projects, :issues, :users

  def setup
    @request.session[:user_id] = 2
    @some_tags = "1, 2, 3,4,5"
    @project_with_tags = setup_project_with_tags(@some_tags)
  end

  def test_should_destroy_issue_tag
    @tag_id = IssueTag.find_by_tag("4")

    delete 'destroy', :project_id => @project_with_tags.id, :id => @tag_id
    assert_response :redirect

    tag_rem = IssueTag.all.size
    assert_equal tag_rem, 4
  end
end
