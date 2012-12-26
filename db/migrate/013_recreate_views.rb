class RecreateViews < ActiveRecord::Migration
  def self.up
    drop_view :issue_tags
    drop_view :wiki_page_tags
    create_view :issue_tags, "select taggings.id as id, tags.name as tag, taggings.taggable_id as issue_id from taggings join tags on taggings.tag_id = tags.id where taggable_type = 'Issue'" 
    create_view :wiki_page_tags, "select taggings.id as id, tags.name as tag, taggings.taggable_id as wiki_page_id from taggings join tags on taggings.tag_id = tags.id where taggable_type = 'WikiPage'" 
  end

  def self.down
    # noop
  end
  
  def up
    self.class.up
  end

  def down
    self.class.down
  end
end

