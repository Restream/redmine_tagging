class FixBrokenIssueAndWikiContexts < ActiveRecord::Migration
  def self.remove_tagging(tagging)
    tag = tagging.tag
    tagging.destroy
    tag.destroy unless tag.taggings.any?
  end

  def self.up

    issue_condition = ["taggable_type = ?", "Issue"]
    wiki_condition = ["taggable_type = ?", "WikiPage"]

    ActsAsTaggableOn::Tagging.find_each(:conditions => issue_condition) do |tagging|
      if tagged_issue = Issue.find_by_id(tagging.taggable_id)
        context_should_be = TaggingPlugin::ContextHelper.context_for(tagged_issue.project)
        if tagging.context != context_should_be 
          tagging.context = context_should_be
          tagging.save
        end
      else
        remove_tagging(tagging)
      end
    end

    ActsAsTaggableOn::Tagging.find_each(:conditions => wiki_condition) do |tagging|
      if tagged_page = WikiPage.find_by_id(tagging.taggable_id)
        project = tagged_page.wiki.project
        context_should_be = TaggingPlugin::ContextHelper.context_for(project)
        if tagging.context != context_should_be 
          tagging.context = context_should_be
          tagging.save
        end
      else
        remove_tagging(tagging)
      end
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

