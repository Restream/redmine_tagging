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

WikiController.send(:include, TaggingPlugin::WikiControllerPatch) unless WikiController.included_modules.include? TaggingPlugin::WikiControllerPatch
ProjectsHelper.send(:include, TaggingPlugin::ProjectsHelperPatch) unless ProjectsHelper.included_modules.include? TaggingPlugin::ProjectsHelperPatch
