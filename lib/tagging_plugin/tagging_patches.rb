require_dependency 'issue'
require_dependency 'wiki_page'

module TaggingPlugin

  module ProjectsHelperPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :project_settings_tabs, :tags_tab
      end
    end

    module InstanceMethods
      def project_settings_tabs_with_tags_tab
        tabs = project_settings_tabs_without_tags_tab
        tabs << { :name => 'tags', :partial => 'tagging/tagtab', :label => :tagging_tab_label}
        return tabs
      end
    end
  end

  module WikiPagePatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        attr_writer :tags_to_update

        before_save :update_tags
        acts_as_taggable

        has_many :wiki_page_tags
      end
    end

    module InstanceMethods
      private
        def update_tags
          if @tags_to_update
            project_context = ContextHelper.context_for(project)
            set_tag_list_on(project_context, @tags_to_update)
          end

          true
        end
    end
  end

  module IssuePatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        attr_writer :tags_to_update

        before_save :update_tags
        acts_as_taggable

        after_save :cleanup_tags

        has_many :issue_tags

        alias_method_chain :create_journal, :tags
        alias_method_chain :init_journal, :tags
      end
    end

    module InstanceMethods
      def create_journal_with_tags
        if @current_journal
          tag_context = ContextHelper.context_for(project)
          before = @issue_tags_before_change
          after = TagsHelper.to_string(tag_list_on(tag_context))
          unless before == after
            @current_journal.details << JournalDetail.new(:property => 'attr',
                                                          :prop_key => 'tags',
                                                          :old_value => before,
                                                          :value => after)
          end
        end
        create_journal_without_tags
      end

      def init_journal_with_tags(user, notes = "")
        tag_context = ContextHelper.context_for(project)
        @issue_tags_before_change = TagsHelper.to_string(tag_list_on(tag_context))
        init_journal_without_tags(user, notes)
      end

      private
        def update_tags
          project_context = ContextHelper.context_for(project)

          # Fix context if project changed
          if project_id_changed? && !new_record?
            @new_project_id = project_id

            taggings.update_all(:context => project_context)
          end

          if @tags_to_update
            set_tag_list_on(project_context, @tags_to_update)
          end

          true
        end

        def cleanup_tags
          if @new_project_id
            context = ContextHelper.context_for(project)
            ActsAsTaggableOn::Tagging.where("
              context!=? AND taggable_id=? AND taggable_type=?",
              context, id, "Issue").delete_all
          end
          true
        end
    end
  end

  module TaggingHelperPatch
    def self.included(base)
      base.class_eval do
        helper :tagging
      end
    end
  end

  module WikiControllerPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        alias_method_chain :update, :tags
      end
    end

    module InstanceMethods
      def update_with_tags
        if params[:wiki_page]
          if tags = params[:wiki_page][:tags]
            tags = TagsHelper.from_string(tags)
            @page.tags_to_update = tags
          end
        end
        update_without_tags
      end
    end
  end
end

Issue.send(:include, TaggingPlugin::IssuePatch) unless Issue.included_modules.include? TaggingPlugin::IssuePatch

WikiPage.send(:include, TaggingPlugin::WikiPagePatch) unless WikiPage.included_modules.include? TaggingPlugin::WikiPagePatch

[IssuesController, ReportsController, WikiController, ProjectsController].each do |controller|
  controller.send(:include, TaggingPlugin::TaggingHelperPatch) unless controller.include? TaggingPlugin::TaggingHelperPatch
end

WikiController.send(:include, TaggingPlugin::WikiControllerPatch) unless WikiController.included_modules.include? TaggingPlugin::WikiControllerPatch

ProjectsHelper.send(:include, TaggingPlugin::ProjectsHelperPatch) unless ProjectsHelper.included_modules.include? TaggingPlugin::ProjectsHelperPatch
