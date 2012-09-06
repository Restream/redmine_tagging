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
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        acts_as_taggable

        has_many :wiki_page_tags
      end
    end

    module ClassMethods
    end

    module InstanceMethods
    end
  end

  module IssuePatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        before_save :update_tags
        acts_as_taggable
        after_save :cleanup_tags

        has_many :issue_tags
        
        alias_method_chain :create_journal, :tags
        alias_method_chain :init_journal, :tags
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def create_journal_with_tags
        if @current_journal
          tag_context = ContextHelper.context_for(project)
          before = @issue_tags_before_change
          after = tag_list_on(tag_context).sort.collect{|tag| tag.gsub(/^#/, '')}.join(' ')
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
        @issue_tags_before_change = tag_list_on(tag_context).sort.collect{|tag| tag.gsub(/^#/, '')}.join(' ')
        init_journal_without_tags(user, notes)
      end

      def tags_to_update=(tags)
        @tags_to_update = tags
      end

      private
        def update_tags
          project_context = ContextHelper.context_for(project)
          
          # Fix context if project changed
          if project_id_changed? && !new_record?
            taggings.update_all(:context => project_context)
          end

          if @tags_to_update
            set_tag_list_on(project_context, @tags_to_update)
          end
          
          true
        end

        def cleanup_tags
          if project_id_changed?
            context = ContextHelper.context_for(project)
            condition = ["context != ? AND taggable_id = ? AND taggable_type= ?", context, id, "Issue"]
            ActsAsTaggableOn::Tagging.delete_all(condition)
          end

          true
        end
    end
  end

  module WikiControllerPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable

        alias_method_chain :edit, :save_tags
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def edit_with_save_tags
        if ! request.get?
          page = @wiki.find_page(params[:page])
          if page
            content = page.content_for_version(params[:version])
            txt = content.text.to_s

            # if the body text wasn't change the after_save hook doesn't
            # get called. This either forces a new space at the end, or
            # removes it if it was already present. This fully undoes the
            # performance gain that was intended by not saving the object
            # because it will always perform 2 requests _and_ save the
            # object, but whatyagonnado...
            if params[:content][:text] == txt
              if txt =~ / $/
                params[:content][:text].rstrip!
              else
                params[:content][:text] += ' '
              end
            end
          end
        end

        return edit_without_save_tags
      end
    end
  end
end

Issue.send(:include, TaggingPlugin::IssuePatch) unless Issue.included_modules.include? TaggingPlugin::IssuePatch

WikiPage.send(:include, TaggingPlugin::WikiPagePatch) unless WikiPage.included_modules.include? TaggingPlugin::WikiPagePatch

WikiController.send(:include, TaggingPlugin::WikiControllerPatch) unless WikiController.included_modules.include? TaggingPlugin::WikiControllerPatch

ProjectsHelper.send(:include, TaggingPlugin::ProjectsHelperPatch) unless ProjectsHelper.included_modules.include? TaggingPlugin::ProjectsHelperPatch
