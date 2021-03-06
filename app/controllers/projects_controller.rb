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
    @subtitle = 'Projects'
  end

  def show
    @project = Project.find(params[:id])
    @subtitle = @project.nome
  end

  def show_analysis
    @analysis = Analysis.find_by_id_and_project_id params[:analysis_id], params[:id]
    render :update do |page|
      page.replace_html "analysis_#{@analysis.id}", :partial => 'analysis'
    end
  end

  def generate_rake_file
    @project = Project.find(params[:id])
    send_data @project.generate_rake_file, :filename => 'inotegration.rake'
  end
end
