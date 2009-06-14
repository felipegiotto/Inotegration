class ProjetosController < ApplicationController

  def analisar
    @projeto = Projeto.find params[:id]
#    Thread.new do
      @projeto.analisar
#    end
    redirect_to @projeto
  end
  
  def index
    @projetos = Projeto.all(:order => 'updated_at DESC')
  end

  def show
    @projeto = Projeto.find(params[:id])
  end

  def edit
    @projeto = Projeto.find(params[:id])
  end

  def update
    @projeto = Projeto.find(params[:id])
    if @projeto.update_attributes(params[:projeto])
      flash[:notice] = 'Projeto was successfully updated.'
      redirect_to(@projeto)
    else
      render :action => "edit"
    end
  end

  def show_analysis
    @analise = Analise.find_by_id_and_projeto_id params[:analysis_id], params[:id]
    render :update do |page|
      dom_id = "analise_#{@analise.id}"
      page.replace_html dom_id, :partial => 'analise'
    end
  end
  
end
