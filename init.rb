require 'redmine'
require 'dispatcher'

Dispatcher.to_prepare do
  require_dependency 'tagging_patches'

  if !Issue.searchable_options[:include].include? :issue_tags
    Issue.searchable_options[:columns] << "#{IssueTag.table_name}.tag"
    Issue.searchable_options[:include] << :issue_tags
  end

  if !WikiPage.searchable_options[:include].include? :wiki_page_tags
    # I now know _way_ to much about activerecord... activerecord
    # builds an SQL string, _then scans that string_ for tables to use
    # in its join constructions. I really do hope that's a temporary
    # workaround. Why it has ever worked is beyond me. Reference:
    # construct_finder_sql_for_association_limiting in
    # active_record/associations.rb
    WikiPage.searchable_options[:columns] = WikiPage.searchable_options[:columns].select{|c| c != 'text'}
    WikiPage.searchable_options[:columns] << "#{WikiContent.table_name}.text"

    WikiPage.searchable_options[:columns] << "#{WikiPageTag.table_name}.tag"
    WikiPage.searchable_options[:include] << :wiki_page_tags
  end
end

require_dependency 'tagging_hooks'

Redmine::Plugin.register :redmine_tagging do
  name 'Redmine Tagging plugin'
  author 'friflaj'
  description 'Wiki/issues tagging'
  version '0.0.1'

  Redmine::WikiFormatting::Macros.register do
    desc "Wiki/Issues tagcloud" 
    macro :tagcloud do |obj, args|
      args, options = extract_macro_options(args, :parent)

      if obj.is_a? WikiContent
        project = obj.page.wiki.project
      else
        project = obj.project
      end

      if !project.nil? # this may be an attempt to render tag cloud when deleting wiki page
        @controller.send(:render_to_string, { :partial => 'tagging/tagcloud', :locals => {:project => project} })
      end
    end
  end 

end
