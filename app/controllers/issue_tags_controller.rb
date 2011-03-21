class IssueTagsController < ApplicationController
  unloadable

  model_object IssueTag
  before_filter :find_model_object
  before_filter :find_project_from_association

  def edit
    @tag = IssueTag.find(params[:id])
  end

  def update
    tag = ActsAsTaggableOn::Tagging.find(params[:id]).tag
    tag.name = '#' + params[:issue_tag][:title]
    tag.save
    flash[:notice] = l(:notice_successful_update)
    redirect_to :controller => 'projects', :action => 'settings', :tab => 'tags', :id => @project
  end

  def destroy
    ActsAsTaggableOn::Tagging.find(params[:id]).tag.taggings.destroy_all
    # redirect_to :action => "edit", :id => params[:id]
    # redirect_to :back
    flash[:notice] = l(:notice_successful_delete)
    redirect_to :controller => 'projects', :action => 'settings', :tab => 'tags', :id => @project
  end


end