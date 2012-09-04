class FixBrokenContexts < ActiveRecord::Migration

  PREFIX = "context_"

  def self.up
    ActsAsTaggableOn::Tagging.find_each do |tagging|
      tagged_issue = Issue.find(tagging.taggable_id)
      context_should_be = TaggingPlugin::ContextHelper.context_for(tagged_issue.project)
      if tagging.context != context_should_be 
        tagging.context = context_should_be
        tagging.save
      end
    end
  end

  def self.down
  end
end

