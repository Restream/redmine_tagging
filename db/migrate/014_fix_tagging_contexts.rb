class FixTaggingContexts < ActiveRecord::Migration

  PREFIX = "context_"

  def self.up
    ActsAsTaggableOn::Tagging.where("context not like ?", PREFIX + "%").find_each do |tagging|
      tagging.context = PREFIX + tagging.context
      tagging.save
    end
  end

  def self.down
    ActsAsTaggableOn::Tagging.where("context like ?", PREFIX + "%").find_each do |tagging|
      tagging.context = tagging.context[PREFIX.length..-1]
      tagging.save
    end
  end

  def up
    self.class.up
  end

  def down
    self.class.down
  end
end

