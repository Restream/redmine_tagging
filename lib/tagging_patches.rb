require_dependency 'issue'
require_dependency 'wiki_page'

module TaggingPlugin
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
  
        acts_as_taggable
  
        has_many :issue_tags
      end
    end
  
    module ClassMethods
    end
  
    module InstanceMethods
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
