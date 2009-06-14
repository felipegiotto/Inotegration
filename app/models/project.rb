class Project < ActiveRecord::Base

  validates_presence_of :folder_name, :nome
  has_many :analyses, :order => 'created_at DESC', :dependent => :destroy

  def self.identify_all
    Dir.chdir RAILS_ROOT + '/projects'
    Dir.glob('*').each do |folder_name|
      Project.find_or_create_by_folder_name :folder_name => folder_name, :nome => folder_name.humanize
    end
  end

  def folder_path
    RAILS_ROOT + '/projects/' + self.folder_name
  end
  
  def description
    File.read(folder_path + '/README')
  end
  
  def situation_verbose
    return 'Pending' if analyses.empty?
    analyses.first.situation_verbose
  end
  
  def last_analysis_at
    analyses.first.try :created_at
  end
  
  def go_to_project_folder
    Dir.chdir folder_path
  rescue
    false
  end
  
  def repository_type
    if File.exists?(folder_path + '/.git')
      :GIT
    elsif File.exists?(folder_path + '/.svn')
      :SVN
    else
      :Nenhum
    end
  end
  
  def last_commit_data
    go_to_project_folder || return
    case repository_type
      when :GIT; `git log -1`
      when :SVN; `svn log -l 1`
      else 'No SCM in use'
    end
  end
  
  def check_for_modifications_and_analyse
    go_to_project_folder || return
    case repository_type
    when :GIT; return if `git pull`.include?('Already up-to-date')
    when :SVN; return if `svn update`.include?('Na revisão')
    else return
    end
    
    analyse
  end
  
  def analyse
    go_to_project_folder || return
    
    result_migration = `rake db:migrate`
    if result_migration.include? 'migrating'
      `rake db:test:prepare`
    else
      result_migration = '' 
    end

    folder_names_to_analyze = ['app']
    folder_names_to_analyze << 'lib' unless Dir.glob('lib/*.rb').empty?
    files_to_analyze = folder_names_to_analyze.collect{|folder_name| "#{folder_name}/**/*.rb"}.join ' '

    unless File.exists?(folder_path + '/config/inotegration.yml')
      File.open folder_path + '/config/inotegration.yml', 'w' do |f|
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
    inotegration_config = YAML::load_file(folder_path + '/config/inotegration.yml')

    analysis = self.analyses.build
    analysis.dados_do_commit = self.last_commit_data
    analysis.texto = result_migration unless result_migration.blank?

    analysis.make 'Unit Tests', Result::FAIL do
      str = `rake test:units`
      break if !str.include? 'Finished'
      if str.include?('0 failures, 0 errors')
        str
      else
        raise str
      end        
    end

=begin
    analysis.make 'Functional Tests', Result::FAIL do
      str = `rake test:functionals`
      break if !str.include? 'Finished'
      if str.include?('0 failures, 0 errors')
        str
      else
        raise str
      end        
    end

    analysis.make 'Code Complexity (Flog)', Result::WARNING do
      flog = Flog.new
      flog.flog_files folder_names_to_analyze
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
        raise "#{bad_methods.length} method(s) with complexity > #{threshold}:\n#{bad_methods.join("\n")}.\nTo change this limit, open file config/inotegration.yml and change 'MaximumFlogComplexity' value."
      end
    end
    
    analysis.make 'Code Duplication', Result::WARNING do
      threshold = inotegration_config['MaximumFlayThreshold'].to_i
      flay = Flay.new({:fuzzy => false, :verbose => false, :mass => threshold})
      flay.process(*Flay.expand_dirs_to_files(folder_names_to_analyze))
    
      if flay.masses.empty?
        "Não há nenhum bloco de código que possua duplicações com limite maior que #{threshold}.\nPara alterar este limite, edite o arquivo config/inotegration.yml e altere a chave 'MaximumFlayThreshold'."
      else
        raise "#{flay.masses.size} code block(s) with duplicated data with threshold #{threshold}:\n#{flay.report_string}.\nPara alterar este limite, edite o arquivo config/inotegration.yml e altere a chave 'MaximumFlayThreshold'."
      end
    end

    analysis.make 'Code Quality (Roodi)', Result::WARNING do
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
    analysis.make 'Code Quality (Reek)', Result::WARNING do
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
    
    analysis.make 'rake stats', Result::WARNING do
      `rake stats`
    end

    self.nome_will_change!
    self.save!
  end
  
end
