class ScrubBody < ActiveRecord::Migration
  def self.up
    Issue.find(:all, :conditions => "description like '%{{tag(%'").each {|issue|
      issue.description = issue.description.gsub(/[{]{2}tag[(][^)]*[)][}]{2}/i, '')
      issue.save!
    }

    WikiContent.find(:all, :conditions => "text like '%{{tag(%'").each {|content|
      content.text = content.text.gsub(/[{]{2}tag[(][^)]*[)][}]{2}/i, '')
      content.save!
    }
    WikiContent::Version.find(:all, :conditions => "data like '%{{tag(%'").each {|content|
      content.data = content.data.gsub(/[{]{2}tag[(][^)]*[)][}]{2}/i, '')
      content.save!
    }
  end

  contexts = Project.find(:all).collect{|p| p.identifier}
  contexts << contexts.collect{|c| c.gsub('-', '_')}
  contexts.flatten!

  ActsAsTaggableOn::Tag.find(:all,
    :conditions => ["not name like '#%' and id in (select tag_id from taggings where taggable_type in ('WikiPage', 'Issue') and context in (?))", contexts]
    ).each {|tag|
      tag.name = "##{tag.name}"
      tag.save
  }

  def self.down
  end

  def up
    self.class.up
  end

  def down
    self.class.down
  end
end

