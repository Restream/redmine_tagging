# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

def setup_issue_with_tags(test_tags)    
  public_project = Project.first(["is_public=?", true])
  some_issue = public_project.issues.first

  some_issue.tags_to_update = test_tags  
  some_issue.save!
  some_issue
end
