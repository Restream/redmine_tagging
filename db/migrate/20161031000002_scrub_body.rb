class ScrubBody < ActiveRecord::Migration
  def up
    Issue.where("description like '%{{tag(%'").each {|issue|
      issue.description = issue.description.gsub(/[{]{2}tag[(][^)]*[)][}]{2}/i, '')
      issue.save!
    }

    WikiContent.where("text like '%{{tag(%'").each {|content|
      content.text = content.text.gsub(/[{]{2}tag[(][^)]*[)][}]{2}/i, '')
      content.save!
    }
    WikiContent::Version.where("data like '%{{tag(%'").each {|content|
      content.data = content.data.gsub(/[{]{2}tag[(][^)]*[)][}]{2}/i, '')
      content.save!
    }
  end

  contexts = Project.where(nil).collect{|p| p.identifier}
  contexts << contexts.collect{|c| c.gsub('-', '_')}
  contexts.flatten!

  ActsAsTaggableOn::Tag.where(
      "not name like '#%' and id in (select tag_id from taggings where taggable_type in ('WikiPage', 'Issue') and context in (?))",
      contexts
  ).each do |tag|
      tag.name = "##{tag.name}"
      tag.save
  end

  def down
    # noop
  end
end

