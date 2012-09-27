# Load the normal Rails helper
require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

def setup_project_with_tags(test_tags)    
  public_project = Project.first(["is_public=?", true])
  some_issue = public_project.issues.first

  context = TaggingPlugin::ContextHelper.context_for(public_project)
  some_issue.set_tag_list_on(context, test_tags)  
  some_issue.save!

  public_project
end