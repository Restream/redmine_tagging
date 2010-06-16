require_dependency 'issue'

module WikiPagePatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)

    base.class_eval do
      unloadable

      acts_as_taggable
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
    end
  end

  module ClassMethods
  end

  module InstanceMethods
  end
end
