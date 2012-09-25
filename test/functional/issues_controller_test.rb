require File.dirname(__FILE__) + '/../test_helper'

class IssuesControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    @request.session[:user_id] = 2
    @some_tags = "#1, #2, #3,#4,#5"

    @issue_with_tags = setup_issue_with_tags(@some_tags)
    @project_with_tags = @issue_with_tags.project

    @another_project = Project.find(:first, :conditions => ["id != ?", @project_with_tags.id])
  end

  def test_bulk_update_with_project_change_should_success
    tag_input = '"1 2 \\\\ 3 cool/tag 777    '
    put :bulk_update, { :ids => Issue.all.map(&:id), :issue => { :tags => tag_input, :project_id => @another_project.id }, 'append_tags' => "on" }
    assert_response :redirect

    @issue_with_tags.reload

    another_project_context = TaggingPlugin::ContextHelper.context_for(@another_project)
    tags = @issue_with_tags.tags_on(another_project_context)      
    assert_equal tags.map(&:name).sort, ['#1', '#2', '#3', '#4', '#5', '#777', '#cool/tag']
  end

  def test_bulk_update_without_project_change_should_success
    tag_input = '"1 2 \\\\ 3 cool/tag 777    '
    put :bulk_update, { :ids => Issue.all.map(&:id), :issue => { :tags => tag_input }, 'append_tags' => "on" }
    assert_response :redirect

    @issue_with_tags.reload

    project_context = TaggingPlugin::ContextHelper.context_for(@project_with_tags)
    tags = @issue_with_tags.tags_on(project_context)      
    assert_equal tags.map(&:name).sort, ['#1', '#2', '#3', '#4', '#5', '#777', '#cool/tag']
  end
end
