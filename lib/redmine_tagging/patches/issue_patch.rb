require_dependency 'issue'

module RedmineTagging::Patches::IssuePatch
  extend ActiveSupport::Concern

  included do
    unloadable

    attr_writer :tags_to_update

    before_save :update_tags
    acts_as_taggable

    after_save :cleanup_tags

    has_many :issue_tags

    alias_method_chain :create_journal, :tags
    alias_method_chain :init_journal, :tags
    alias_method_chain :copy_from, :tags

    if Redmine::VERSION::MAJOR < 3
      searchable_options[:columns] << "#{IssueTag.table_name}.tag"
      searchable_options[:include] ||= []
      searchable_options[:include] << :issue_tags
    else
      searchable_options[:columns] << "#{IssueTag.table_name}.tag"

      original_scope = searchable_options[:scope] || self

      searchable_options[:scope] = ->(*args) {
        (original_scope.respond_to?(:call) ?
          original_scope.call(*args) :
          original_scope
        ).includes :issue_tags
      }
    end
  end

  def create_journal_with_tags
    if @current_journal
      tag_context = TaggingPlugin::ContextHelper.context_for(project)
      before      = @issue_tags_before_change
      after       = TaggingPlugin::TagsHelper.to_string(tag_list_on(tag_context))
      unless before == after
        @current_journal.details << JournalDetail.new(
          property:  'attr',
          prop_key:  'tags',
          old_value: before,
          value:     after)
      end
    end
    create_journal_without_tags
  end

  def init_journal_with_tags(user, notes = "")
    unless project.nil?
      tag_context               = TaggingPlugin::ContextHelper.context_for(project)
      @issue_tags_before_change = TaggingPlugin::TagsHelper.to_string(tag_list_on(tag_context))
    end
    init_journal_without_tags(user, notes)
  end

  def tags
    issue_tags.map(&:to_s).join(' ')
  end

  def copy_from_with_tags(arg, options = {})
    copy_from_without_tags(arg, options)
    issue             = arg.is_a?(Issue) ? arg : Issue.visible.find(arg)
    self.tag_list_ctx = issue.tag_list_ctx
    self
  end

  def tag_list_ctx
    tag_context = TaggingPlugin::ContextHelper.context_for(project)
    tag_list_on(tag_context)
  end

  def tag_list_ctx=(new_list)
    tag_context = TaggingPlugin::ContextHelper.context_for(project)
    set_tag_list_on(tag_context, new_list)
  end

  private

  def update_tags
    project_context = TaggingPlugin::ContextHelper.context_for(project)

    # Fix context if project changed
    if project_id_changed? && !new_record?
      @new_project_id = project_id

      taggings.update_all(context: project_context)
    end

    if @tags_to_update
      set_tag_list_on(project_context, @tags_to_update)
    end

    true
  end

  def cleanup_tags
    if @new_project_id
      context = TaggingPlugin::ContextHelper.context_for(project)
      ActsAsTaggableOn::Tagging.where(
        'context != ? AND taggable_id = ? AND taggable_type = ?', context, id, 'Issue'
      ).delete_all
    end
    true
  end
end

unless Issue.included_modules.include? RedmineTagging::Patches::IssuePatch
  Issue.send :include, RedmineTagging::Patches::IssuePatch
end
