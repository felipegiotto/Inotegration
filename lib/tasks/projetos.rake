
namespace :projetos do
  task :testar do
    require File.join(File.dirname(__FILE__), '../../config/environment')
    require 'flay'
    require 'flog'
    Projeto.identificar_todos
    Projeto.all.each(&:verificar_atualizacoes_e_analisar)
  end
end