class ProjectsController < ApplicationController

  def analisar
    @project = Project.find params[:id]
#    Thread.new do
      @project.analisar
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
    @analise = Analise.find_by_id_and_project_id params[:analysis_id], params[:id]
    render :update do |page|
      dom_id = "analise_#{@analise.id}"
      page.replace_html dom_id, :partial => 'analise'
    end
  end
  
end
