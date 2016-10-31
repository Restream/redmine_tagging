class FixTaggingContexts < ActiveRecord::Migration

  PREFIX = "context_"

  def up
    ActsAsTaggableOn::Tagging.where("context not like ?", PREFIX + "%").find_each do |tagging|
      tagging.context = PREFIX + tagging.context
      tagging.save
    end
  end

  def down
    ActsAsTaggableOn::Tagging.where("context like ?", PREFIX + "%").find_each do |tagging|
      tagging.context = tagging.context[PREFIX.length..-1]
      tagging.save
    end
  end
end

