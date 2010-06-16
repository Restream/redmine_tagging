class TaggingController < ApplicationController
  unloadable

  before_filter :find_optional_project, :authorize

  def index
    @tags = params[:tags].split

    @issues = Issue.tagged_with(@tags, :on => @project.identifier)
    @wikipages = WikiPage.tagged_with(@tags, :on => @project.identifier)

    render :action => "tagged"
  end
end
