require File.dirname(__FILE__) + '/../test_helper'

class TaggingTest < ActionDispatch::IntegrationTest
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
    Mailer.stubs(:deliver_mail).returns(true)

    log_user('admin', 'admin')
    User.any_instance.stubs(:allowed_to?).returns(true)

    @some_tags = '#1, #2, #3,#4,#5'

    @project_with_tags = Project.find(1)
    @another_project = Project.find(2)

    @issue_with_tags = Issue.find(1)
    @issue_with_tags.tags_to_update = @some_tags
    @issue_with_tags.save!

    @issue_without_tags = Issue.find(2)

    @wiki_page_with_tags = setup_wiki_page_with_tags(@some_tags)
    @wiki_page_with_tags_content = @wiki_page_with_tags.content

    @project_with_wiki_tags = @wiki_page_with_tags.project

    @another_project_context = TaggingPlugin::ContextHelper.context_for(@another_project)
    @project_with_tags_context = TaggingPlugin::ContextHelper.context_for(@project_with_tags)

    @project_with_wiki_tags_context = TaggingPlugin::ContextHelper.context_for(@project_with_wiki_tags)
  end

  def test_should_create_issue_tags_from_input
    Setting.plugin_redmine_tagging[:issues_inline] = '0'

    @new_issue_attrs = {
      'project_id'  => @project_with_tags.id,
      'priority_id' => @issue_with_tags.priority_id,
      'subject'     => 'new_issue',
      'tags'        => '10 11 12'
    }

    get_via_redirect(new_project_issue_path(@project_with_tags))
    assert_response :success
    post_via_redirect(issues_path, issue: @new_issue_attrs)
    assert_response :success

    new_issue = Issue.find_by_subject('new_issue')
    assert_equal 3, new_issue.taggings.size
    assert_equal [@project_with_tags_context], new_issue.taggings.map(&:context).uniq
  end

  def test_should_update_issue_tags_from_input
    Setting.plugin_redmine_tagging[:issues_inline] = '0'

    issue_attrs = @issue_with_tags.attributes

    issue_attrs['project_id'] = @another_project.id
    issue_attrs['tracker'] = @another_project.trackers.first
    issue_attrs['tags'] = '10 11 12'

    get_via_redirect(edit_issue_path(@issue_with_tags))
    assert_response :success
    put_via_redirect(issue_path(@issue_with_tags), issue: issue_attrs)
    assert_response :success
    get_via_redirect(issue_path(@issue_with_tags))
    assert_response :success

    @issue_with_tags.reload
    assert_equal 3, @issue_with_tags.taggings.size
    assert_equal [@another_project_context], @issue_with_tags.taggings.map(&:context).uniq
  end

  def test_should_create_inline_issue_tags
    Setting.plugin_redmine_tagging[:issues_inline] = '1'

    @new_issue_attrs = {
      'project_id'  => @project_with_tags.id,
      'priority_id' => @issue_with_tags.priority_id,
      'subject'     => 'new_issue',
      'description' => '{{tag(10 11 12)}}'
    }

    get_via_redirect(new_project_issue_path(@project_with_tags))
    assert_response :success
    post_via_redirect(issues_path, issue: @new_issue_attrs)
    assert_response :success

    new_issue = Issue.find_by_subject('new_issue')
    assert_equal 3, new_issue.taggings.size
    assert_equal [@project_with_tags_context], new_issue.taggings.map(&:context).uniq
  end

  def test_should_update_inline_issue_tags
    Setting.plugin_redmine_tagging[:issues_inline] = '1'

    issue_attrs = @issue_with_tags.attributes

    issue_attrs['project_id'] = @another_project.id
    issue_attrs['tracker'] = @another_project.trackers.first
    issue_attrs['description'] = '{{tag(6)}} {{tag(7 8)}}'

    get_via_redirect(edit_issue_path(@issue_with_tags))
    assert_response :success
    put_via_redirect(issue_path(@issue_with_tags), issue: issue_attrs)
    assert_response :success
    get_via_redirect(issue_path(@issue_with_tags))
    assert_response :success

    @issue_with_tags.reload
    assert_equal 2, @issue_with_tags.taggings.count
    assert_equal [@another_project_context], @issue_with_tags.taggings.map(&:context).uniq
  end

  def test_should_generate_wiki_tagcloud
    edit_page_path = edit_wiki_cpath(@project_with_wiki_tags, 'newpage')
    page_path = wiki_cpath(@project_with_wiki_tags, 'newpage')

    page_content = @wiki_page_with_tags_content.attributes.merge(
      'text' => '{{tag(11)}} {{tag(14 15)}} {{tagcloud}}'
    )

    page_attrs = @wiki_page_with_tags.attributes

    get_via_redirect(edit_page_path)
    assert_response :success
    put_via_redirect(page_path, wiki_page: page_attrs, content: page_content)
    assert_response :success
    get_via_redirect(page_path)
    assert_response :success
  end

  def test_should_create_wiki_page_tags_from_input
    Setting.plugin_redmine_tagging[:wiki_pages_inline] = '0'

    edit_page_path = edit_wiki_cpath(@project_with_wiki_tags, 'newpage')
    page_path = wiki_cpath(@project_with_wiki_tags, 'newpage')

    page_content = @wiki_page_with_tags_content.attributes
    page_attrs = @wiki_page_with_tags.attributes
    page_attrs['title'] = 'Newpage'
    page_attrs['tags'] = '10 11 12'

    get_via_redirect(edit_page_path)
    assert_response :success
    put_via_redirect(page_path, wiki_page: page_attrs, content: page_content)
    assert_response :success
    get_via_redirect(page_path)
    assert_response :success

    new_page = WikiPage.find_by_title('Newpage')
    assert_equal 3, new_page.taggings.size
    assert_equal [@project_with_wiki_tags_context], new_page.taggings.map(&:context).uniq
  end

  def test_should_update_wiki_page_tags_from_input
    Setting.plugin_redmine_tagging[:wiki_pages_inline] = '0'

    edit_page_path = edit_wiki_cpath(@project_with_wiki_tags, @wiki_page_with_tags.title)
    page_path = wiki_cpath(@project_with_wiki_tags, @wiki_page_with_tags.title)
    page_content = @wiki_page_with_tags_content.attributes
    page_attrs = @wiki_page_with_tags.attributes
    page_attrs['tags'] = '10 11 12'

    get_via_redirect(edit_page_path)
    assert_response :success
    put_via_redirect(page_path, wiki_page: page_attrs, content: page_content)
    assert_response :success
    get_via_redirect(page_path)
    assert_response :success

    @wiki_page_with_tags.reload
    assert_equal 3, @wiki_page_with_tags.taggings.size
    assert_equal [@project_with_wiki_tags_context], @wiki_page_with_tags.taggings.map(&:context).uniq
  end

  def test_should_create_inline_wiki_page_tags
    Setting.plugin_redmine_tagging[:wiki_pages_inline] = '1'

    edit_page_path = edit_wiki_cpath(@project_with_wiki_tags, 'newpage')
    page_path = wiki_cpath(@project_with_wiki_tags, 'newpage')

    page_content = @wiki_page_with_tags_content.attributes.merge(
      'text' => '{{tag(11)}} {{tag(14 15)}}'
    )

    page_attrs = @wiki_page_with_tags.attributes.merge(
      'title' => 'Newpage'
    )

    get_via_redirect(edit_page_path)
    assert_response :success
    put_via_redirect(page_path, wiki_page: page_attrs, content: page_content)
    assert_response :success
    get_via_redirect(page_path)
    assert_response :success

    new_page = WikiPage.find_by_title('Newpage')
    assert_equal 2, new_page.taggings.size
    assert_equal [@project_with_wiki_tags_context], new_page.taggings.map(&:context).uniq
  end

  def test_should_update_inline_wiki_page_tags
    Setting.plugin_redmine_tagging[:wiki_pages_inline] = '1'

    edit_page_path = edit_wiki_cpath(@project_with_wiki_tags, @wiki_page_with_tags.title)
    page_path = wiki_cpath(@project_with_wiki_tags, @wiki_page_with_tags.title)

    page_content = @wiki_page_with_tags_content.attributes.merge(
      'text' => '{{tag(11)}} {{tag(14 15)}}'
    )

    page_attrs = @wiki_page_with_tags.attributes

    get_via_redirect(edit_page_path)
    assert_response :success
    put_via_redirect(page_path, wiki_page: page_attrs, content: page_content)
    assert_response :success
    get_via_redirect(page_path)
    assert_response :success

    @wiki_page_with_tags.reload
    assert_equal 2, @wiki_page_with_tags.taggings.size
    assert_equal [@project_with_wiki_tags_context], @wiki_page_with_tags.taggings.map(&:context).uniq
  end

  def wiki_cpath(project, page)
    project_wiki_page_path(project, page)
  rescue NoMethodError
    project_wiki_path(project, page)
  end

  def edit_wiki_cpath(project, page)
    edit_project_wiki_page_path(project, page)
  rescue NoMethodError
    edit_project_wiki_path(project, page)
  end
end
