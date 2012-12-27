class FixTagsWithBackslash < ActiveRecord::Migration
  def self.up
    ActsAsTaggableOn::Tag.find_each(:conditions => ["name like ?", '%\\\%']) do |tag|
      tag.name = tag.name.gsub("\\", '/')
      tag.save
    end
  end

  def self.down
  end

  def up
    self.class.up
  end

  def down
    self.class.down
  end
end
