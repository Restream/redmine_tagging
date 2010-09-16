require 'redmine'

require 'tagging_patches'

ActionController::Dispatcher.to_prepare do
    require_dependency 'issue'
    require_dependency 'wiki_page'

    WikiPage.send(:include, WikiPagePatch) unless WikiPage.included_modules.include? WikiPagePatch
    Issue.send(:include, IssuePatch) unless Issue.included_modules.include? IssuePatch
end

require_dependency 'tagging_hooks'

Redmine::Plugin.register :redmine_tagging do
  name 'Redmine Tagging plugin'
  author 'friflaj'
  description 'Wiki/issues tagging'
  version '0.0.1'

  #project_module :tagging do
    #permission :view_project, :tagging => :index
  #end
  Redmine::AccessControl.permission(:view_project).actions << 'tagging/index'

  Redmine::WikiFormatting::Macros.register do
    desc "Wiki/Issues tag" 
    macro :tag do |obj, args|
      args, options = extract_macro_options(args, :parent)
      tags = args.collect{|a| a.split}.flatten.collect{|tag| tag.gsub(/[^-0-9a-zA-Z]/, '') }.uniq.sort

      if obj.is_a? WikiContent
        obj = obj.page
        project = obj.wiki.project
      else
        project = obj.project
      end
      context = project.identifier.gsub('-', '_')

      # only save if there are differences
      if obj.tag_list_on(context).sort.join(',') != tags.join(',')
        obj.set_tag_list_on(context, tags.join(', '))
        obj.save
      end

      taglinks = tags.collect{|tag|
        link_to("##{tag}", {:controller => "tagging", :action => "index", :project_id => project.identifier, :tags => tag})
      }.join('&nbsp;')
      "<div class='tags'>#{taglinks}</div>"
    end
  end 

  Redmine::WikiFormatting::Macros.register do
    desc "Wiki/Issues tagcloud" 
    macro :tagcloud do |obj, args|
      args, options = extract_macro_options(args, :parent)

      if obj.is_a? WikiContent
        project = obj.page.wiki.project
      else
        project = obj.project
      end

      @controller.send(:render_to_string, { :partial => 'tagging/tagcloud', :locals => {:project => project} })
    end
  end 

end
