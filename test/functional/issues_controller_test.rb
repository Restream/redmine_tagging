require File.dirname(__FILE__) + '/../test_helper'

class IssuesControllerTest < ActionController::TestCase
  fixtures :projects, :issues, :users, :trackers

  def setup
    @request.session[:user_id] = 2
    User.stubs(:current).returns(User.find_by_id(2))
    User.any_instance.stubs(:allowed_to?).returns(true)
    Mailer.stubs(:deliver_mail).returns(true)
    @some_tags = "#1, #2, #3,#4,#5"

    @issue_with_tags = setup_issue_with_tags(@some_tags)
    @issue_without_tags = setup_issue_with_tags("")

    @issues_to_bulk_edit = [@issue_with_tags, @issue_without_tags]

    @project_with_tags = @issue_with_tags.project
    @another_project = Project.generate!

    Issue.stubs(:allowed_target_projects_on_move).returns(Project.all)
  end

  def test_can_index_issues_when_custom_fields_available
    IssueCustomField.create!({
      :name => "cfield",
      :default_value => "ok",
      :is_filter => true,
      :field_format => "string",
      :is_for_all => true
    })

    get :index
    assert_response :success
  end

  def test_can_index_api
    get :index, :format => 'json'
    assert_response :success
  end

  def test_can_show_api
    get :show, :id => @issue_with_tags.id, :format => 'xml'
    assert_response :success
  end

  def test_index_api_rsb_should_not_raise_in_project_issues
    get :index, :project_id => @project_with_tags.id
  end

  def test_can_show_api_for_some_project
    get :index, :format => 'json', :project_id => @project_with_tags.id
    assert_response :success
  end

  def test_bulk_update_with_project_change_should_success
    tag_input = '"1 2 \\\\ 3 cool/tag 777    '

    put :bulk_update, { :ids => @issues_to_bulk_edit.map(&:id), :issue => { :project_id => @another_project.id, :tags => tag_input }, :append_tags =>"on" }

    assert_response :redirect

    @issue_with_tags.reload

    another_project_context = TaggingPlugin::ContextHelper.context_for(@another_project)
    tags = @issue_with_tags.tags_on(another_project_context)      
    assert_equal ['#1', '#2', '#3', '#4', '#5', '#777', '#cool/tag'], tags.map(&:name).sort
  end

  def test_bulk_update_without_project_change_should_success
    tag_input = '"1 2 \\\\ 3 cool/tag 777    '
    put :bulk_update, { :ids => @issues_to_bulk_edit.map(&:id), :issue => { :tags => tag_input }, 'append_tags' => "on" }
    assert_response :redirect

    @issue_with_tags.reload

    project_context = TaggingPlugin::ContextHelper.context_for(@project_with_tags)
    tags = @issue_with_tags.tags_on(project_context)      
    assert_equal ['#1', '#2', '#3', '#4', '#5', '#777', '#cool/tag'], tags.map(&:name).sort
  end

  def test_bulk_update_without_tags_field_should_not_drop_tags
    put :bulk_update, { :ids => @issues_to_bulk_edit.map(&:id), :issue => { :status_id => 1 }}
    assert_response :redirect

    @issue_with_tags.reload

    project_context = TaggingPlugin::ContextHelper.context_for(@project_with_tags)
    tags = @issue_with_tags.tags_on(project_context)
    assert_equal ['#1', '#2', '#3', '#4', '#5'], tags.map(&:name).sort
  end
end
