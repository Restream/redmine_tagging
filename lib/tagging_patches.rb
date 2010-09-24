require_dependency 'issue'
require_dependency 'wiki_page'

module Tagging
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
end

Issue.send(:include, Tagging::IssuePatch) unless Issue.included_modules.include? Tagging::IssuePatch

WikiPage.send(:include, Tagging::WikiPagePatch) unless WikiPage.included_modules.include? Tagging::WikiPagePatch
