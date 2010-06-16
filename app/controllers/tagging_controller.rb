class TaggingController < ApplicationController
  unloadable

  before_filter :find_optional_project, :authorize

  def index
    @tags = params[:tags].split

    @issues = Issue.tagged_with(@tags, :on => @project.identifier).sort {|a, b|
      if b.closed? == a.closed?
        b.updated_on <=> a.updated_on
      else
        (b.closed? ? 1 : 0) <=> (a.closed? ? 1 : 0)
      end
    }
    @wikipages = WikiPage.tagged_with(@tags, :on => @project.identifier)

    render :action => "tagged"
  end
end
