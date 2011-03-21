class IssueTag < ActiveRecord::Base
  belongs_to :issue

  def readonly?
    return true
  end

  def title
    tag.gsub(/^#/, '')
  end

  def project
    # self.issue.project
    Issue.find(issue_id).project
  end

  # Prevent objects from being destroyed
  def before_destroy
    raise ActiveRecord::ReadOnlyRecord
  end
end
