module TaggingPlugin
  module Hooks
    class LayoutHook < Redmine::Hook::ViewListener

      def view_issues_sidebar_planning_bottom(context = {})
        sidebar_tagcloud? ? render_partial_to_string(context, 'tagging/tagcloud') : ''
      end

      def view_wiki_sidebar_bottom(context = {})
        sidebar_tagcloud? ? render_partial_to_string(context, 'tagging/tagcloud_search') : ''
      end

      def view_layouts_base_html_head(context = {})
        tagging_stylesheet = stylesheet_link_tag 'tagging', plugin: 'redmine_tagging'

        unless ((sidebar_tagcloud? &&
          context[:controller].is_a?(WikiController)) ||
          (context[:controller].is_a?(IssuesController) &&
            context[:controller].action_name == 'bulk_edit'))
          return tagging_stylesheet
        end

        sidebar_tags = if sidebar_tagcloud?
          tag_cloud = render_partial_to_string(context, 'tagging/tagcloud_search')
          "$('#sidebar').append(\"#{escape_javascript(tag_cloud)}\")"
        else
          ''
        end

        <<-TAGS
#{ tagging_stylesheet }
        #{ javascript_include_tag 'toggle_tags', plugin: 'redmine_tagging' }
          <script type="text/javascript">
            //<![CDATA[
            $(function() {
              #{sidebar_tags}
              $('#cloud_content').toggleCloudViaFor($('#cloud_trigger'), $('#issue_tags'))
            })
            //]]>
          </script>
        TAGS
      end

      def view_issues_show_details_bottom(context = {})
        return '' if issues_inline_tags?

        issue       = context[:issue]
        tag_context = ContextHelper.context_for(issue.project)
        tags        = issue.tag_list_on(tag_context).sort_by { |t| t.downcase }

        render_partial_to_string(context, 'tagging/taglinks', tags: tags)
      end

      def view_issues_form_details_bottom(context={})
        return '' if issues_inline_tags?

        issue  = context[:issue]
        result = ''

        if context[:request].params[:issue] # update form
          tags   = context[:request].params[:issue][:tags]
          result += issue_tag_field context[:form], tags
        else
          tag_context = ContextHelper.context_for(issue.project)
          tags        = issue.tag_list_on(tag_context) \
            .sort_by { |t| t.downcase } \
            .map { |tag| tag.gsub(/^#/, '') } \
            .join(' ')
          result      += issue_tag_field context[:form], tags
        end

        unless context[:request].xhr?
          result += javascript_include_tag 'tag', plugin: 'redmine_tagging'
          result += javascript_include_tag 'toggle_tags', plugin: 'redmine_tagging'
        end

        result + issue_cloud_javascript(context)
      end

      def controller_issues_bulk_edit_before_save(context={})
        return if issues_inline_tags? || !has_tags_in_params?(context[:params])

        tags  = context[:params]['issue']['tags'].to_s
        issue = context[:issue]

        if context[:params]['append_tags']
          tag_context = if issue.project_id_changed?
            ContextHelper.context_for(Project.find(issue.project_id_was))
          else
            ContextHelper.context_for(issue.project)
          end

          old_tags = issue.tags_on(tag_context)

          tags += ' ' + TagsHelper.to_string(old_tags.map(&:name)) if old_tags.present?
        end

        issue.tags_to_update = TagsHelper.from_string(tags)
      end

      def controller_issues_edit_before_save(context={})
        return if issues_inline_tags?
        return unless has_tags_in_params?(context[:params])

        issue = context[:issue]
        tags  = context[:params]['issue']['tags'].to_s

        tags                 = TagsHelper.from_string(tags)
        issue.tags_to_update = tags
      end

      alias_method :controller_issues_new_before_save, :controller_issues_edit_before_save

      # wikis have no view hooks
      def view_layouts_base_content(context={})
        return '' if wiki_pages_inline_tags?

        return '' unless context[:controller].is_a?(WikiController)

        request = context[:request]

        return '' unless request.parameters

        project = Project.find_by_identifier(request.parameters['project_id'])
        return '' unless project

        page = project.wiki.find_page(request.parameters['id'])

        tag_context = ContextHelper.context_for(project)
        tags        = ''

        if page && request.parameters['action'] == 'index'
          tags = page.tag_list_on(tag_context).sort_by { |t| t.downcase }.map do |tag|
            link_to(tag, {
              controller: 'search',
              action:     'index',
              project_id: project,
              q:          tag_without_sharp(tag),
              wiki_pages: true,
              issues:     true })
          end.join('&nbsp;')

          tags = "<h3>#{ l(:field_tags) }:</h3><p>#{ tags }</p>" if tags
        end

        action = request.parameters['action']

        if action == 'edit' || (!page && action == 'show')
          if page
            tags = TagsHelper.to_string(page.tag_list_on(tag_context))
          else
            tags = ""
          end

          tags = "<p id='tagging_wiki_edit_block'><label>#{l(:field_tags)}</label><input id='wiki_page_tags' name='wiki_page[tags]' size='120' type='text' value='#{h(tags)}'/></p>"

          ac = ActsAsTaggableOn::Tag.where(
            "id in (select tag_id from taggings where taggable_type in ('WikiPage', 'Issue') and context = ?)",
            tag_context
          ).collect { |tag| tag.name }

          ac = ac.collect { |tag| "'#{escape_javascript(tag.gsub(/^#/, ''))}'" }.join(', ')

          tags += javascript_include_tag 'tag', plugin: 'redmine_tagging'

          tags += <<-generatedscript
            <script type="text/javascript">
              $(document).ready(function() {
                $('#tagging_wiki_edit_block').insertAfter($("#content_text"))
                $('#wiki_page_tags').tagSuggest({ tags: [#{ac}] })
              })
            </script>
          generatedscript
        end

        return tags
      end

      def view_issues_bulk_edit_details_bottom(context = {})
        <<-HTML
          <p>
            <label>#{ l(:field_tags) }</label>
            #{ text_field_tag 'issue[tags]', '', size: 18 }<br>
            <input type="checkbox" name="append_tags" checked="checked" />
            #{ l(:append_tags) }<br>
          </p>
          <p>
            #{ render_partial_to_string(context, 'tagging/issue_tagcloud') }
          </p>
        HTML
      end

      def view_reports_issue_report_split_content_right(context={})
        project_context = ContextHelper.context_for(context[:project])
        tags            = ActsAsTaggableOn::Tagging.find_all_by_context(project_context).map(&:tag).uniq
        tags_by_status  = IssueTag.by_issue_status(context[:project])

        <<-HTML
          <h3>#{ l(:field_tags) } &nbsp;&nbsp;</h3>
          #{ render_partial_to_string(context, 'reports/simple_tags',
                                      data: tags_by_status, field_name: 'tag', rows: tags) }<br/>
        HTML
      end

      private

      def has_tags_in_params?(params)
        params && params['issue'] && params['issue']['tags']
      end

      def issues_inline_tags?
        Setting.plugin_redmine_tagging[:issues_inline] == '1'
      end

      def wiki_pages_inline_tags?
        Setting.plugin_redmine_tagging[:wiki_pages_inline] == '1'
      end

      def sidebar_tagcloud?
        Setting.plugin_redmine_tagging[:sidebar_tagcloud] == '1'
      end

      def render_partial_to_string(context, partial_name, options = {})
        context[:controller].send :render_to_string,
                                  partial: partial_name,
                                  locals:  context.merge(options)
      end

      def issue_tag_field(form, tags = '')
        '<p>' + form.text_field(:tags, autocomplete: 'off', value: tags) + '</p>'
      end

      def issue_cloud_javascript(context)
        tag_context = ContextHelper.context_for(context[:issue].project)
        ac          = ActsAsTaggableOn::Tag.where(
          "id in (select tag_id from taggings where taggable_type in ('WikiPage', 'Issue') and context = ?)",
          tag_context)
        ac          = ac.map { |tag| "'#{escape_javascript(tag.to_s.gsub(/^\s*#/, ''))}'" }.join(', ')

        cloud = render_partial_to_string(context, 'tagging/issue_tagcloud')

        <<-generatedscript
          <script type="text/javascript">
            //<![CDATA[
            $(document).ready(function() {
              $('#issue_tags').tagSuggest({ tags: [#{ac}] });
              var tags_container = $('#issue_tags').parent();
              var cloud = $("<div>#{escape_javascript(cloud)}</div>");
              $(tags_container).append(cloud);
              $('#cloud_content').toggleCloudViaFor($('#cloud_trigger'), $('#issue_tags'));
            });
            //]]>
          </script>
        generatedscript
      end

    end
  end
end
