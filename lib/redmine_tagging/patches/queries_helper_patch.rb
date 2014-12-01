module RedmineTagging::Patches::QueriesHelperPatch
  extend ActiveSupport::Concern

  included do
    alias_method_chain :column_content, :tags
  end

  def column_content_with_tags(column, issue)
    value = column.value(issue)

    if array_of_issue_tags?(value)
      links = value.map do |issue_tag|
        link_to_project_tag_filter(@project, issue_tag.tag)
      end
      links.join(', ')
    else
      column_content_without_tags(column, issue)
    end
  end

  def array_of_issue_tags?(value)
    value.class.name == 'Array' && value.first.class.name == 'IssueTag'
  end
end
