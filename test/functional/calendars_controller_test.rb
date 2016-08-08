require File.dirname(__FILE__) + '/../test_helper'

class CalendarsControllerTest < ActionController::TestCase
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

    @issue_with_tags = Issue.find(1)
    @issue_with_tags.tags_to_update = @some_tags
    @issue_with_tags.save!
  end

  def test_can_show_calendar
    get :show, project_id: @project_with_tags.id
    assert_response :success
  end
end
