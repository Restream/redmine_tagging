require File.dirname(__FILE__) + '/../test_helper'

class IssueTagsControllerTest < ActionController::TestCase
  fixtures :projects,
    :users,
    :roles,
    :members,
    :member_roles,
    :trackers,
    :projects_trackers,
    :enabled_modules,
    :issue_statuses,
    :issues,
    :enumerations,
    :custom_fields,
    :custom_values,
    :custom_fields_trackers

  def setup
    @request.session[:user_id] = 2
    @some_tags = '#1, #2, #3,#4,#5'

    @project_with_tags = Project.find(1)
    @another_project = Project.find(2)

    @issue_with_tags = Issue.find(1)
    @issue_with_tags.tags_to_update = @some_tags
    @issue_with_tags.save!
  end

  def test_should_destroy_issue_tag
    @tag_id = ActsAsTaggableOn::Tag.find_by_name('#4').id

    delete 'destroy', project_id: @project_with_tags.id, id: @tag_id
    assert_response :redirect

    tag_rem = ActsAsTaggableOn::Tag.count
    assert_equal 4, tag_rem
  end

  def test_should_destroy_issue_tag_in_case_of_changed_project
    @issue_with_tags.project_id = @another_project.id
    @issue_with_tags.save!
    @issue_with_tags.reload

    @tag_id = ActsAsTaggableOn::Tag.find_by_name('#4').id
    delete 'destroy', project_id: @another_project.id, id: @tag_id
    assert_response :redirect

    tag_rem = ActsAsTaggableOn::Tag.count
    assert_equal 4, tag_rem
  end
end
