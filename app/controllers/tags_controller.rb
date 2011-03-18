class TagsController < ApplicationController

  def new
  end

  def edit
    @tag = IssueTag.find(params[:id])
  end

  def create
  end

  def delete
  end

  def destroy
  end


end