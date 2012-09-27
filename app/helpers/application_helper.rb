module ApplicationHelper
  def link_to_project_tag_filter(project, tag, options = {})
    options.reverse_merge!({
      :status => '*',
      :title => tag
    })

    opts = {
      'set_filter' => 1,
      'f' => ['tags', 'status_id'],
      'op[tags]' => '=',
      'op[status_id]' => options[:status],
      'v[tags][]' => tag,
      'v[status_id][]' => 1
    }

    if project
      link_to(options[:title], project_issues_path(project, opts))
    else
      link_to(options[:title], issues_path(opts))
    end
  end
end
