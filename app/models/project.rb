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
    if File.exists? folder_path + '/README'
      File.read(folder_path + '/README')
    end
  end
  
  def situation_verbose
    return 'Warnings' if analyses.empty?
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
    analyse if fetch_modifications || analyses.empty?
  end
  
  def fetch_modifications
    go_to_project_folder || return
    case repository_type
    when :GIT; 
      return if `git pull`.include?('Already up-to-date')
    when :SVN; 
      output = `svn update`
      return if output.blank? || output.include?('Na revisão') || output.include?('At revision')
    else return
    end
    return true
  end
  
  def create_default_config_file_if_needed
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
  end

  def analyse
    go_to_project_folder || return
    
    migration_info = `rake db:migrate`
    if migration_info.include? 'migrating'
      `rake db:test:prepare`
    else
      migration_info = nil
    end

    folder_names_to_analyse = ['app']
    folder_names_to_analyse << 'lib' unless Dir.glob('lib/*.rb').empty?
    files_to_analyse = folder_names_to_analyse.collect{|folder_name| "#{folder_name}/**/*.rb"}.join ' '

    create_default_config_file_if_needed
    
    inotegration_config = YAML::load_file(folder_path + '/config/inotegration.yml')

    analysis = self.analyses.build
    analysis.commit_data = self.last_commit_data
    analysis.migration_data = migration_info
    analysis.save!
    
    analysis.make 'Spec', Result::FAIL do
      str = `rake spec`
      break if !str.include? 'Finished'
      if str.include?('0 failures')
        str
      else
        raise str
      end        
    end

    analysis.make 'Unit Tests', Result::FAIL do
      str = `rake test:units`
      break if !str.include? 'Finished'
      if str.include?('0 failures, 0 errors')
        str
      else
        raise str
      end        
    end

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
      flog.flog_files folder_names_to_analyse
      threshold = inotegration_config['MaximumFlogComplexity'].to_i
    
      bad_methods = flog.totals.select do |name, score|
        score > threshold
      end
      
      if bad_methods.empty?
        "No method found with complexity > #{threshold}.\nTo change this limit, check README file."
      else
        bad_methods = bad_methods.sort { |a,b| a[1] <=> b[1] }.collect do |name, score|
          "%8.1f: %s" % [score, name]
        end
        raise "#{bad_methods.length} method(s) with complexity > #{threshold}:\n#{bad_methods.join("\n")}.\nTo change this limit, check README file."
      end
    end
    
    analysis.make 'Code Duplication', Result::WARNING do
      threshold = inotegration_config['MaximumFlayThreshold'].to_i
      flay = Flay.new({:fuzzy => false, :verbose => false, :mass => threshold})
      flay.process(*Flay.expand_dirs_to_files(folder_names_to_analyse))
    
      if flay.masses.empty?
        "No code block with duplication > #{threshold}.\nTo change this limit, check README file."
      else
        raise "#{flay.masses.size} code block(s) with duplicated data with threshold #{threshold}:\n#{flay.report_string}.\nTo change this limit, check README file."
      end
    end

    analysis.make 'Code Quality (Roodi)', Result::WARNING do
      if inotegration_config['RoodiConfig'].blank?
        str = `roodi app/**/*.rb lib/**/*.rb`
      else
        File.open 'tmp/roodi.yml', 'w' do |f|
          f.puts inotegration_config['RoodiConfig'].to_yaml
        end
        str = `roodi -config=tmp/roodi.yml #{files_to_analyse}`
      end
      if str.include?('Found 0 errors')
        str
      else
        raise str
      end        
    end
    
    analysis.make 'Code Quality (Reek)', Result::WARNING do
      if inotegration_config['ReekConfig'].blank?
        File.delete 'site.reek' if File.exists? 'site.reek'
      else
        File.open 'site.reek', 'w' do |f|
          f.puts inotegration_config['ReekConfig'].to_yaml
        end
      end
      begin
        str = `reek #{files_to_analyse}`
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

    analysis.finished = true
    analysis.save!
    self.updated_at_will_change!
    self.save!
  end
  
end
