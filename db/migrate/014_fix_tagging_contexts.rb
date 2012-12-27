class FixTaggingContexts < ActiveRecord::Migration

  PREFIX = "context_"

  def self.up
    to_fix = ["context not like ?", PREFIX + "%"]
    ActsAsTaggableOn::Tagging.find_each(:conditions => to_fix) do |tagging|
      tagging.context = PREFIX + tagging.context
      tagging.save
    end
  end

  def self.down
    to_fix = ["context like ?", PREFIX + "%"]
    ActsAsTaggableOn::Tagging.find_each(:conditions => to_fix) do |tagging|
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

