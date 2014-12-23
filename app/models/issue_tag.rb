class IssueTag < ActiveRecord::Base
  self.table_name = :issue_tags
  self.primary_key = :id

  belongs_to :issue

  def readonly?
    return true
  end

  def title
    tag.gsub(/^#/, '')
  end
  alias_method :name, :title

  def project
    # self.issue.project
    Issue.find(issue_id).project
  end

  # Prevent objects from being destroyed
  def before_destroy
    raise ActiveRecord::ReadOnlyRecord
  end

  def self.by_issue_status(project = nil)
    project_condition = project.nil? ? '' : "and i.project_id=#{project.id}"

    ActiveRecord::Base.connection.select_all(
      "select
        s.id as status_id,
        s.is_closed as closed,
        t.id as tag,
        count(i.id) as total
      from
        #{Issue.table_name} i, #{IssueStatus.table_name} s,
        #{ActsAsTaggableOn::Tagging.table_name} ti, #{ActsAsTaggableOn::Tag.table_name} t
      where
        i.status_id=s.id
        and ti.taggable_id=i.id
        and ti.tag_id=t.id
        #{project_condition}
      group
        by s.id, s.is_closed, t.id")
  end

  def to_s
    name
  end
end
