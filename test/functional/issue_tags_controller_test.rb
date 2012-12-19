require File.dirname(__FILE__) + '/../test_helper'

class IssueTagsControllerTest < ActionController::TestCase
  fixtures :projects, :issues, :users, :trackers, :issue_statuses

  def setup
    @request.session[:user_id] = 2
    @some_tags = "#1, #2, #3,#4,#5"

    @issue_with_tags = setup_issue_with_tags(@some_tags)
    @project_with_tags = @issue_with_tags.project
    @another_project = Project.generate!
  end

  def test_should_destroy_issue_tag
    @tag_id = ActsAsTaggableOn::Tag.find_by_name("#4").id

    delete 'destroy', :project_id => @project_with_tags.id, :id => @tag_id
    assert_response :redirect

    tag_rem = ActsAsTaggableOn::Tag.count
    assert_equal 4, tag_rem
  end

  def test_should_destroy_issue_tag_in_case_of_changed_project
    @issue_with_tags.project = @another_project

    some_tracker = @issue_with_tags.project.trackers.create!(:name => "test")
    @issue_with_tags.tracker = some_tracker
    @issue_with_tags.save!
    @issue_with_tags.reload

    @tag_id = ActsAsTaggableOn::Tag.find_by_name("#4").id
    delete 'destroy', :project_id => @another_project.id, :id => @tag_id
    assert_response :redirect

    tag_rem = ActsAsTaggableOn::Tag.count
    assert_equal 4, tag_rem
  end
end
