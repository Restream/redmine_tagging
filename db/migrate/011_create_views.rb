class CreateViews < ActiveRecord::Migration
  def self.up
    execute <<-SQL
      CREATE VIEW issue_tags AS
      SELECT
        taggings.id AS id,
        tags.name AS tag,
        taggings.taggable_id AS issue_id
      FROM
        taggings
          JOIN tags ON taggings.tag_id = tags.id
      WHERE
        taggable_type = 'Issue'
    SQL

    execute <<-SQL
      CREATE VIEW wiki_page_tags AS
      SELECT
        taggings.id,
        tags.name AS tag,
        taggings.taggable_id AS wiki_page_id
      FROM
        taggings
          JOIN tags ON taggings.tag_id = tags.id
      WHERE
        taggable_type = 'WikiPage'
    SQL
  end

  def self.down
    execute 'DROP VIEW issue_tags'
    execute 'DROP VIEW wiki_page_tags'
  end

  def up
    self.class.up
  end

  def down
    self.class.down
  end
end

