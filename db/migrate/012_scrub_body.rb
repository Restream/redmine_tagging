class ScrubBody < ActiveRecord::Migration
  def self.up
    Issue.find(:all, :conditions => "lower(description) like '%{{tag(%'").each {|issue|
      issue.description = issue.description.gsub(/[{]{2}tag[(][^)]*[)][}]{2}/i, '')
      issue.save!
    }

    WikiContent.find(:all, :conditions => "lower(text) like '%{{tag(%'").each {|content|
      content.text = content.text.gsub(/[{]{2}tag[(][^)]*[)][}]{2}/i, '')
      content.save!
    }
    WikiContent::Version.find(:all, :conditions => "lower(data) like '%{{tag(%'").each {|content|
      content.data = content.data.gsub(/[{]{2}tag[(][^)]*[)][}]{2}/i, '')
      content.save!
    }
  end

  def self.down
  end
end

