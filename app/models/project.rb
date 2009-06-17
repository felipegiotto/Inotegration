class Project < ActiveRecord::Base

  validates_presence_of :folder_name, :nome
  has_many :analyses, :order => 'created_at DESC', :dependent => :destroy

  def self.identify_all
    Dir.chdir RAILS_ROOT + '/projects'
    Dir.glob('*/config/environment.rb').each do |project|
      folder_name = project.match(%r{(.*)/config/environment.rb})[1]
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
      return unless `git pull`.include?('files changed')
    when :SVN; 
      output = `svn update`
      return unless output.include?('Atualizado para') || output.include?('Updated to')
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

  PREPARE_ENVIRONMENT = <<-PREPARE_ENVIRONMENT
    folder_names_to_analyse = ['app']
    files_to_analyse = 'app/**/*.rb'
    unless Dir.glob('lib/*.rb').empty?
      folder_names_to_analyse << 'lib'
      files_to_analyse += ' lib/*.rb'
    end
PREPARE_ENVIRONMENT

  def generate_rake_file
    ERB.new(File.read(RAILS_ROOT + '/app/views/projects/rake_task.erb')).result(binding)
  end

  def analyse
    go_to_project_folder || return
    
    migration_info = `rake db:migrate RAILS_ENV=development`
    if migration_info.include? 'migrating'
      `rake db:test:prepare`
    else
      migration_info = nil
    end

    return if Dir.glob('config').empty? || Dir.glob('lib').empty?

    create_default_config_file_if_needed
    inotegration_config = YAML::load_file(folder_path + '/config/inotegration.yml')
    
    eval PREPARE_ENVIRONMENT

    analysis = self.analyses.build
    analysis.commit_data = self.last_commit_data
    analysis.migration_data = migration_info
    analysis.save!

    InotegrationTests.constants.each do |test|
      test_data = InotegrationTests.const_get test
      analysis.make test_data[0], test_data[1] do
        eval test_data[2]
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
