module TaggingPlugin
  module Hooks
    class LayoutHook < Redmine::Hook::ViewListener
      def view_issues_new_top(context={})
        return '' if Setting.plugin_redmine_tagging[:sidebar_tagcloud] != "1"

        cloud = context[:controller].send(:render_to_string, {
            :partial => 'tagging/issue_tagcloud',
            :locals => context
          })

        result = <<-TAGS
          #{javascript_include_tag 'jquery_loader', :plugin => 'redmine_tagging'}
          #{javascript_include_tag 'toggle_visibility', :plugin => 'redmine_tagging'}
          <script type="text/javascript">
            var $j = jQuery.noConflict()
            $j(function() {
              var tags_container = $j('#issue_tags').parent()
              var cloud = $j("<div>#{escape_javascript(cloud)}</div>")
              $j(tags_container).append(cloud)
              $j('#cloud_content').toggleVisibilityVia($j('#cloud_trigger'))
            })
          </script>
        TAGS

        return result
      end

      def view_issues_sidebar_planning_bottom(context={})
        return '' if Setting.plugin_redmine_tagging[:sidebar_tagcloud] != "1"

        return context[:controller].send(:render_to_string, {
            :partial => 'tagging/tagcloud',
            :locals => context
          })
      end

      def view_wiki_sidebar_bottom(context={})
        return '' if Setting.plugin_redmine_tagging[:sidebar_tagcloud] != "1"

        return context[:controller].send(:render_to_string, {
            :partial => 'tagging/tagcloud_search',
            :locals => context
          })
      end

      def view_layouts_base_html_head(context={})


        if Setting.plugin_redmine_tagging[:sidebar_tagcloud] == "1"
          tag_cloud = context[:controller].send(:render_to_string, {
            :partial => 'tagging/tagcloud_search',
            :locals => context
          })

          sidebar_tags = "$j('#sidebar').append(\"#{escape_javascript(tag_cloud)}\")"
        else
          sidebar_tags = ''
        end

        result = <<-TAGS
          #{javascript_include_tag 'jquery_loader', :plugin => 'redmine_tagging'}
          #{javascript_include_tag 'toggle_visibility', :plugin => 'redmine_tagging'}
          <script type="text/javascript">
            var $j = jQuery.noConflict()
            $j(function() {
              #{sidebar_tags}
              $j('#cloud_content').toggleVisibilityVia($j('#cloud_trigger'))
            })
          </script>
        TAGS

        <<-TAGCLOUD
          #{result}
          <style>
            span.tagMatches {
              margin-left: 10px;
            }

            span.tagMatches span {
              padding: 2px;
              margin-right: 4px;
              background-color: #0000AB;
              color: #fff;
              cursor: pointer;
            }
          </style>
        TAGCLOUD
      end

      def view_issues_show_details_bottom(context={})
        return '' if Setting.plugin_redmine_tagging[:issues_inline] == "1"

        issue = context[:issue]
        snippet = ''
        tag_context = ContextHelper.context_for(issue.project)
        tags = issue.tag_list_on(tag_context).sort

        return context[:controller].send(:render_to_string, {
            :partial => 'tagging/taglinks',
            :locals => {:tags => tags }
          })
      end

      def view_issues_form_details_bottom(context={})
        return '' if Setting.plugin_redmine_tagging[:issues_inline] == "1"

        issue = Issue.visible.find_by_id(context[:issue].id) || context[:issue]

        tag_context = ContextHelper.context_for(issue.project)

        tags = issue.tag_list_on(tag_context).sort.collect{|tag| tag.gsub(/^#/, '')}.join(' ')

        tags = '<p>' + context[:form].text_field(:tags, :value => tags) + '</p>'
        tags += javascript_include_tag 'jquery_loader', :plugin => 'redmine_tagging'
        tags += javascript_include_tag 'tag', :plugin => 'redmine_tagging'

        ac = ActsAsTaggableOn::Tag.find(:all,
            :conditions => ["id in (select tag_id from taggings
            where taggable_type in ('WikiPage', 'Issue') and context = ?)", tag_context]).collect {|tag| tag.name}
        ac = ac.collect{|tag| "'#{escape_javascript(tag.gsub(/^#/, ''))}'"}.join(', ')
        tags += <<-generatedscript
          <script type="text/javascript">
            var $j = jQuery.noConflict()
            $j(document).ready(function() {
              $j('#issue_tags').tagSuggest({ tags: [#{ac}] })
            })
          </script>
        generatedscript

        return tags
      end

      def controller_issues_bulk_edit_before_save(context={})
        return if Setting.plugin_redmine_tagging[:issues_inline] == "1"
        return unless context[:params] && context[:params]['issue']
        return unless context[:params]['issue']['tags']

        tags = context[:params]['issue']['tags'].to_s
        issue = context[:issue]

        if context[:params]['append_tags']
          if issue.project_id_changed?
            tag_context = ContextHelper.context_for(Project.find(issue.project_id_was))
          else
            tag_context = ContextHelper.context_for(issue.project)
          end

          oldtags = issue.tags_on(tag_context)
          if oldtags.present?
            tags += ' ' + TagsHelper.to_string(oldtags.map(&:name))
          end
        end

        tags = TagsHelper.from_string(tags)
        issue.tags_to_update = tags
      end

      def controller_issues_edit_before_save(context={})
        return if Setting.plugin_redmine_tagging[:issues_inline] == "1"
        return unless context[:params] && context[:params]['issue']

        issue = context[:issue]
        tags = context[:params]['issue']['tags'].to_s

        tags = TagsHelper.from_string(tags)
        issue.tags_to_update = tags
      end

      alias_method :controller_issues_new_before_save, :controller_issues_edit_before_save

      # wikis have no view hooks
      def view_layouts_base_content(context={})
        return '' if Setting.plugin_redmine_tagging[:wiki_pages_inline] == "1"

        return '' unless context[:controller].is_a?(WikiController)

        request = context[:request]

        return '' unless request.parameters

        project = Project.find_by_identifier(request.parameters['project_id'])
        return '' unless project

        page = project.wiki.find_page(request.parameters['id'])

        tag_context = ContextHelper.context_for(project)
        tags = ''

        if page && request.parameters['action'] == 'index'
          tags = page.tag_list_on(tag_context).sort.collect {|tag|
            link_to("#{tag}", {:controller => "search", :action => "index", :project_id => project, :q => tag, :wiki_pages => true, :issues => true})
          }.join('&nbsp;')

          tags = "<h3>#{l(:field_tags)}:</h3><p>#{tags}</p>" if tags
        end

        action = request.parameters['action']
        
        if action == 'edit' || (!page && action == 'show')
          if page
            tags = TagsHelper.to_string(page.tag_list_on(tag_context))
          else
            tags = ""
          end

          tags = "<p id='tagging_wiki_edit_block'><label>#{l(:field_tags)}</label><input id='wiki_page_tags' name='wiki_page[tags]' size='120' type='text' value='#{h(tags)}'/></p>"

          ac = ActsAsTaggableOn::Tag.find(:all,
              :conditions => ["id in (select tag_id from taggings
              where taggable_type in ('WikiPage', 'Issue') and context = ?)", tag_context]).collect {|tag| tag.name}
          ac = ac.collect{|tag| "'#{escape_javascript(tag.gsub(/^#/, ''))}'"}.join(', ')

          tags += javascript_include_tag 'jquery_loader', :plugin => 'redmine_tagging'
          tags += javascript_include_tag 'tag', :plugin => 'redmine_tagging'

          tags += <<-generatedscript
            <script type="text/javascript">
              var $j = jQuery.noConflict()
              $j(document).ready(function() {
                $j('#tagging_wiki_edit_block').insertAfter($j("#content_text"))
                $j('#wiki_page_tags').tagSuggest({ tags: [#{ac}] })
              })
            </script>
          generatedscript
        end

        return tags
      end

      def view_issues_bulk_edit_details_bottom(context={})

        cloud = context[:controller].send(:render_to_string, {
            :partial => 'tagging/issue_tagcloud',
            :locals => context
        })

        field = "<p>
            <label>#{ l(:field_tags) }</label>
            #{ text_field_tag 'issue[tags]', '', :size => 18 }<br>
            <input type=\"checkbox\" name=\"append_tags\" checked=\"checked\">
            #{ l(:append_tags) }<br>
          </p>"
        return field + "<p>" + cloud + "</p>"
      end

      def view_reports_issue_report_split_content_right(context={})
        project_context = ContextHelper.context_for(context[:project])
        @tags = ActsAsTaggableOn::Tagging \
          .find_all_by_context(project_context) \
          .map(&:tag).uniq
        @tags_by_status = IssueTag.by_issue_status(context[:project])
        report = "<h3>"
        report += "#{l(:field_tags)} &nbsp;&nbsp;"
        report += "</h3>"
        report += context[:controller].send(:render_to_string, :partial => 'reports/simple_tags', :locals => {
          :data => @tags_by_status,
          :field_name => "tag",
          :rows => @tags })
        report += "<br/>"
        return report
      end

    end
  end
end
