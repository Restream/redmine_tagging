require_dependency 'wiki_page'

module RedmineTagging::Patches::WikiPagePatch
  extend ActiveSupport::Concern

  included do
    unloadable

    attr_writer :tags_to_update

    has_many :wiki_page_tags

    acts_as_taggable

    before_save :update_tags

    if Redmine::VERSION::MAJOR < 3
      searchable_options[:columns] << "#{WikiPageTag.table_name}.tag"
      searchable_options[:include] ||= []
      searchable_options[:include] << :wiki_page_tags
    else
      searchable_options[:columns] << "#{WikiPageTag.table_name}.tag"

      original_scope = searchable_options[:scope] || self

      searchable_options[:scope] = ->(*args) {
        (original_scope.respond_to?(:call) ?
          original_scope.call(*args) :
          original_scope
        ).includes :wiki_page_tags
      }
    end
  end

  private

  def update_tags
    if @tags_to_update
      project_context = TaggingPlugin::ContextHelper.context_for(project)
      set_tag_list_on(project_context, @tags_to_update)
    end

    true
  end

end

unless WikiPage.included_modules.include? RedmineTagging::Patches::WikiPagePatch
  WikiPage.send :include, RedmineTagging::Patches::WikiPagePatch
end
