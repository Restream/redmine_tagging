require File.dirname(__FILE__) + '/../test_helper'

class TaggingTest < ActionController::IntegrationTest
  fixtures :all

  def setup
    log_user("admin", "admin")

    @some_tags = "#1, #2, #3,#4,#5"
    @issue_with_tags = setup_issue_with_tags(@some_tags)
    

    @project_with_tags = @issue_with_tags.project
    @another_project = Project.find(:first, :conditions => ["id != ?", @project_with_tags.id])
  
    @another_project_context = TaggingPlugin::ContextHelper.context_for(@another_project)
  end

  def test_should_create_tags_from_input
    Setting.plugin_redmine_tagging[:issues_inline] = "0"

    @new_issue_attrs = @issue_with_tags.attributes.merge({
      "subject" => "new_issue",
      "tags" => "10 11 12"
    })

    post_via_redirect(issues_path, :issue => @new_issue_attrs)
    assert_response :success
     
    new_issue = Issue.find_by_subject("new_issue")
    assert_equal 3, new_issue.taggings.size
  end

  def test_should_update_tags_from_input
    Setting.plugin_redmine_tagging[:issues_inline] = "0"

    issue_attrs = @issue_with_tags.attributes

    issue_attrs['project_id'] = @another_project.id
    issue_attrs['tracker'] = @another_project.trackers.first
    issue_attrs['tags'] = "10 11 12"

    put_via_redirect(issue_path(@issue_with_tags), :issue => issue_attrs)
    assert_response :success
    get_via_redirect(issue_path(@issue_with_tags))
    assert_response :success

    @issue_with_tags.reload
    assert_equal 3, @issue_with_tags.taggings.size
    assert_equal [@another_project_context], @issue_with_tags.taggings.map(&:context).uniq
  end

  def test_should_create_inline_tags
    Setting.plugin_redmine_tagging[:issues_inline] = "1"

    @new_issue_attrs = @issue_with_tags.attributes.merge({
      "subject" => "new_issue",
      "description" => "{{tag(10 11 12)}}"
    })

    post_via_redirect(issues_path, :issue => @new_issue_attrs)
    assert_response :success
     
    new_issue = Issue.find_by_subject("new_issue")
    assert_equal 3, new_issue.taggings.size
  end

  def test_should_update_inline_tags
    Setting.plugin_redmine_tagging[:issues_inline] = "1"

    issue_attrs = @issue_with_tags.attributes

    issue_attrs['project_id'] = @another_project.id
    issue_attrs['tracker'] = @another_project.trackers.first
    issue_attrs['description'] = "{{tag(6)}} {{tag(7 8)}}"

    put_via_redirect(issue_path(@issue_with_tags), :issue => issue_attrs)
    assert_response :success
    get_via_redirect(issue_path(@issue_with_tags))
    assert_response :success

    @issue_with_tags.reload
    assert_equal 2, @issue_with_tags.taggings.size
    assert_equal [@another_project_context], @issue_with_tags.taggings.map(&:context).uniq
  end
end
