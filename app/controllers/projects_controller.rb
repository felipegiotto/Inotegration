class ProjectsController < ApplicationController

  def analisar
    @project = Project.find params[:id]
#    Thread.new do
      @project.analyse
#    end
    redirect_to @project
  end
  
  def index
    @projects = Project.all(:order => 'updated_at DESC')
  end

  def show
    @project = Project.find(params[:id])
  end

  def edit
    @project = Project.find(params[:id])
  end

  def update
    @project = Project.find(params[:id])
    if @project.update_attributes(params[:project])
      flash[:notice] = 'Projeto was successfully updated.'
      redirect_to(@project)
    else
      render :action => "edit"
    end
  end

  def show_analysis
    @analysis = Analysis.find_by_id_and_project_id params[:analysis_id], params[:id]
    render :update do |page|
      page.replace_html "analysis_#{@analysis.id}", :partial => 'analysis'
    end
  end
  
end
