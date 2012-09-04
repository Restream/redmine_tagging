class IssueTagsController < ApplicationController
  unloadable

  model_object ActsAsTaggableOn::Tag
  before_filter :find_model_object
  before_filter :find_project_by_project_id

  def destroy
    tag = @object

    context = TaggingPlugin::ContextHelper.context_for(@project)

    tag.taggings.find(:all, :conditions => ['context = ?', context]).
      each{ |tg| tg.destroy }

    tag.destroy unless tag.taggings.any?

    flash[:notice] = l(:notice_successful_detached)
    redirect_to :controller => 'projects', :action => 'settings', :tab => 'tags', :id => @project
  end
end
