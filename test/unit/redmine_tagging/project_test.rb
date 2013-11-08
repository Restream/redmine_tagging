require File.dirname(__FILE__) + '/../../test_helper'

class RedmineTagging::ProjectTest < ActiveSupport::TestCase
  fixtures :projects, :trackers, :issue_statuses, :issues,
           :enumerations, :users, :issue_categories,
           :projects_trackers,
           :roles,
           :member_roles,
           :members

  def test_find_all_tags_for_project
    project1 = Project.find(1)

    issue = project1.issues.find(1)
    issue.tags_to_update = '4, 2'
    issue.save!

    issue = project1.issues.find(2)
    issue.tags_to_update = '3, 1'
    issue.save!

    project2 = Project.find(3)

    issue = project2.issues.find(5)
    issue.tags_to_update = '8, 6'
    issue.save!

    issue = project2.issues.find(13)
    issue.tags_to_update = '7, 5'
    issue.save!

    tags1 = project1.tags.map(&:name).join(',')
    tags2 = project2.tags.map(&:name).join(',')

    assert_equal '1,2,3,4', tags1
    assert_equal '5,6,7,8', tags2
  end
end
