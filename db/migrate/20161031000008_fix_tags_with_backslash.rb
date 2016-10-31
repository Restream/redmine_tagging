class FixTagsWithBackslash < ActiveRecord::Migration
  def up
    ActsAsTaggableOn::Tag.where("name like ?", '%\\\%').find_each do |tag|
      tag.name = tag.name.gsub("\\", '/')
      tag.save
    end
  end

  def down
  end
end
