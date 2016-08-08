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
        tabs << { name: 'tags', partial: 'tagging/tagtab', label: :tagging_tab_label }
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

WikiPage.send(:include, TaggingPlugin::WikiPagePatch) unless WikiPage.included_modules.include? TaggingPlugin::WikiPagePatch

WikiController.send(:include, TaggingPlugin::WikiControllerPatch) unless WikiController.included_modules.include? TaggingPlugin::WikiControllerPatch

ProjectsHelper.send(:include, TaggingPlugin::ProjectsHelperPatch) unless ProjectsHelper.included_modules.include? TaggingPlugin::ProjectsHelperPatch
