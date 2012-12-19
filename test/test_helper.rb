# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

require 'test/unit/util/backtracefilter'

module Test::Unit::Util::BacktraceFilter
  def filter_backtrace(backtrace, prefix=nil)
    backtrace
  end
end

def setup_issue_with_tags(test_tags)
  public_project = Project.generate!(:is_public => true)
  tracker = Tracker.generate!
  priority = IssuePriority.new(:name => "test_priority#{public_project.id}")
  priority.save!
  public_project.trackers << tracker

  issue = Issue.generate!(:project_id => public_project.id, :tracker => tracker, :priority => priority)

  issue.tags_to_update = test_tags
  issue.save!
  issue
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
