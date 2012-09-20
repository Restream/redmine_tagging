# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

def setup_issue_with_tags(test_tags)
  public_project = Project.first(["is_public=?", true])
  some_issue = public_project.issues.first

  some_issue.tags_to_update = test_tags
  some_issue.save!
  some_issue
end

def setup_wiki_page_with_tags(test_tags)
  public_project = Project.generate!(:is_public => true)

  Wiki.create!(:project_id => public_project.id, :start_page => "test_page")
  public_project.reload

  public_project.wiki.pages << WikiPage.new(:title => "some_wiki_page")
  page = public_project.wiki.pages.first
  page.tags_to_update = test_tags
  page.content = WikiContent.new(:text => "content")
  page.save!
  page
end
