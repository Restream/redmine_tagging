module TaggingPlugin
  module Hooks
    class LayoutHook < Redmine::Hook::ViewListener
      def view_issues_sidebar_planning_bottom(context={ })
        return context[:controller].send(:render_to_string, {
            :partial => 'tagging/tagcloud',
            :locals => context
          })
      end

      def view_issues_show_details_bottom(context={ })
        issue = context[:issue]
        snippet = ''

        tag_context = issue.project.identifier.gsub('-', '_')

        tags = issue.tag_list_on(tag_context).sort.collect {|tag|
          link_to("#{tag}", {:controller => "search", :action => "index", :id => issue.project, :q => tag, :wiki_pages => true, :issues => true})
        }.join('&nbsp;')

        tags = "<tr><th>#{l(:field_tags)}</th><td>#{tags}</td></tr>" if tags

        return tags
      end

      def view_issues_form_details_bottom(context={ })
        issue = context[:issue]

        tag_context = issue.project.identifier.gsub('-', '_')

        tags = issue.tag_list_on(tag_context).sort.join(' ')

        return '<p>' + context[:form].text_field(:tags, :value => tags) + '</p>'
      end

      def controller_issues_edit_after_save(context = {})
        return unless context[:params] && context[:params]['issue']

        issue = context[:issue]
        tags = context[:params]['issue']['tags'].to_s

        tags = tags.split(/[\s,]+/).join(', ')
        tag_context = issue.project.identifier.gsub('-', '_')

        issue.set_tag_list_on(tag_context, tags)
        issue.save
      end

      # wikis have no view hooks
      def view_layouts_base_content(context = {})
        return '' unless context[:controller].is_a? WikiController

        request = context[:request]
        return '' unless request.parameters

        project = Project.find_by_identifier(request.parameters['id'])
        return '' unless project

        page = project.wiki.find_page(request.parameters['page'])
        return '' unless page

        tag_context = project.identifier.gsub('-', '_')
        tags = ''

        if request.parameters['action'] == 'index'
          tags = page.tag_list_on(tag_context).sort.collect {|tag|
            link_to("#{tag}", {:controller => "search", :action => "index", :id => project, :q => tag, :wiki_pages => true, :issues => true})
          }.join('&nbsp;')

          tags = "<h3>#{l(:field_tags)}</h3><p>#{tags}</p>" if tags
        end

        if request.parameters['action'] == 'edit'
          tags = page.tag_list_on(tag_context).sort.join(' ')
          tags = "<p
          id='tagging_wiki_edit_field'><label>#{l(:field_tags)}</label><br /><input id='wikipage_tags' name='wikipage_tags' size='120' type='text' value='#{h(tags)}'/></p>"

          # we add marker data at the end of the body because
          # otherwise the save method doesn't get called. This is
          # nuts, people.
          tags += javascript_include_tag 'jquery-1.4.2.min.js', :plugin => 'redmine_tagging'
          tags += <<-generatedscript
            <script type="text/javascript">
              var $j = jQuery.noConflict();
              $j(document).ready(function() {
                $j('#tagging_wiki_edit_field').insertAfter($j("#content_text").parent().parent());
              });
            </script>
          generatedscript
        end

        return tags
      end

      def controller_wiki_edit_after_save(context = {})
        return unless context[:params]

        project = context[:page].wiki.project

        tags = context[:params]['wikipage_tags'].to_s.split(/[\s,]+/).join(', ')
        tag_context = project.identifier.gsub('-', '_')

        context[:page].set_tag_list_on(tag_context, tags)
        context[:page].save
      end

    end
  end
end
