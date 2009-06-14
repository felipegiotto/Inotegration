class Project < ActiveRecord::Base

  validates_presence_of :pasta, :nome
  has_many :analises, :order => 'created_at DESC', :dependent => :destroy

  def self.identificar_todos
    Dir.chdir RAILS_ROOT + '/projects'
    Dir.glob('*').each do |pasta|
      Project.find_or_create_by_pasta :pasta => pasta, :nome => pasta.humanize
    end
  end

  def pasta_completa
    RAILS_ROOT + '/projects/' + self.pasta
  end
  
  def descricao
    File.read(pasta_completa + '/README')
  end
  
  def situation_verbose
    return 'Pending' if analises.empty?
    analises.first.situation_verbose
  end
  
  def ultima_analise
    analises.first.try :created_at
  end
  
  def ir_para_pasta_do_project
    Dir.chdir pasta_completa
  rescue
    false
  end
  
  def repositorio
    if File.exists?(pasta_completa + '/.git')
      :GIT
    elsif File.exists?(pasta_completa + '/.svn')
      :SVN
    else
      :Nenhum
    end
  end
  
  def dados_do_ultimo_commit
    ir_para_pasta_do_project || return
    case repositorio
      when :GIT; `git log -1`
      when :SVN; `svn log -l 1`
      else 'Nenhum repositório habilitado'
    end
  end
  
  def verificar_atualizacoes_e_analisar
    ir_para_pasta_do_project || return
    case repositorio
    when :GIT; return if `git pull`.include?('Already up-to-date')
    when :SVN; return if `svn update`.include?('Na revisão')
    else return
    end
    
    analisar
  end
  
  def analisar
    ir_para_pasta_do_project || return
    
    resultado_migration = `rake db:migrate`
    if resultado_migration.include? 'migrating'
      `rake db:test:prepare`
    else
      resultado_migration = '' 
    end

    folders_to_analyze = ['app']
    folders_to_analyze << 'lib' unless Dir.glob('lib/*.rb').empty?
    files_to_analyze = folders_to_analyze.collect{|folder| "#{folder}/**/*.rb"}.join ' '

    unless File.exists?(pasta_completa + '/config/inotegration.yml')
      File.open pasta_completa + '/config/inotegration.yml', 'w' do |f|
        f.puts <<-DEFAULT_CONFIG_FILE
MaximumFlogComplexity: 10
MaximumFlayThreshold: 10
RoodiConfig:
  # Insert here your custom roody checks, like:
  # ClassNameCheck:                  { pattern: !ruby/regexp /^[A-Z][a-zA-Z0-9]*$/ }
ReekConfig:
  # Insert here your custom reek checks, like:
  # NestedIterators: 
  #  enabled: false
DEFAULT_CONFIG_FILE
      end
    end
    inotegration_config = YAML::load_file(pasta_completa + '/config/inotegration.yml')

    analise = self.analises.build
    analise.dados_do_commit = self.dados_do_ultimo_commit
    analise.texto = resultado_migration unless resultado_migration.blank?

    analise.analisar 'Testes Unitários', Resultado::FAIL do
      str = `rake test:units`
      break if !str.include? 'Finished'
      if str.include?('0 failures, 0 errors')
        str
      else
        raise str
      end        
    end

=begin
    analise.analisar 'Testes Funcionais', Resultado::FAIL do
      str = `rake test:functionals`
      break if !str.include? 'Finished'
      if str.include?('0 failures, 0 errors')
        str
      else
        raise str
      end        
    end

    analise.analisar 'Complexidade de Código', Resultado::WARNING do
      flog = Flog.new
      flog.flog_files folders_to_analyze
      threshold = inotegration_config['MaximumFlogComplexity'].to_i
    
      bad_methods = flog.totals.select do |name, score|
        score > threshold
      end
      
      if bad_methods.empty?
        "Nenhum método com complexidade maior que #{threshold} foi encontrado.\nPara alterar este limite, edite o arquivo config/inotegration.yml e altere a chave 'MaximumFlogComplexity'."
      else
        bad_methods = bad_methods.sort { |a,b| a[1] <=> b[1] }.collect do |name, score|
          "%8.1f: %s" % [score, name]
        end
        raise "#{bad_methods.length} método(s) com complexidade maior que #{threshold}:\n#{bad_methods.join("\n")}.\nPara alterar este limite, edite o arquivo config/inotegration.yml e altere a chave 'MaximumFlogComplexity'."
      end
    end
    
    analise.analisar 'Duplicação de Código', Resultado::WARNING do
      threshold = inotegration_config['MaximumFlayThreshold'].to_i
      flay = Flay.new({:fuzzy => false, :verbose => false, :mass => threshold})
      flay.process(*Flay.expand_dirs_to_files(folders_to_analyze))
    
      if flay.masses.empty?
        "Não há nenhum bloco de código que possua duplicações com limite maior que #{threshold}.\nPara alterar este limite, edite o arquivo config/inotegration.yml e altere a chave 'MaximumFlayThreshold'."
      else
        raise "#{flay.masses.size} blocos de código possuem dados duplicados com limite maior que #{threshold}:\n#{flay.report_string}.\nPara alterar este limite, edite o arquivo config/inotegration.yml e altere a chave 'MaximumFlayThreshold'."
      end
    end

    analise.analisar 'Qualidade de Código Roodi', Resultado::WARNING do
      if inotegration_config['RoodiConfig'].blank?
        str = `roodi app/**/*.rb lib/**/*.rb`
      else
        File.open 'tmp/roodi.yml', 'w' do |f|
          f.puts inotegration_config['RoodiConfig'].to_yaml
        end
        str = `roodi -config=tmp/roodi.yml #{files_to_analyze}`
      end
      if str.include?('Found 0 errors')
        str
      else
        raise str
      end        
    end
    
=end
    analise.analisar 'Qualidade de Código Reek', Resultado::WARNING do
      if inotegration_config['ReekConfig'].blank?
        File.delete 'site.reek' if File.exists? 'site.reek'
      else
        File.open 'site.reek', 'w' do |f|
          f.puts inotegration_config['ReekConfig'].to_yaml
        end
      end
      begin
        str = `reek #{files_to_analyze}`
        if str.blank?
          "No bad smells found in this project"
        else
          raise str
        end
      ensure
        File.delete 'site.reek' if File.exists? 'site.reek'
      end
    end
    
    analise.analisar 'rake stats', Resultado::WARNING do
      `rake stats`
    end

    self.nome_will_change!
    self.save!
  end
  
end
