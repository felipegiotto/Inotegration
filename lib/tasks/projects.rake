
namespace :projects do

  desc "Identify new projects and run the analysis suite on the changed projects"
  task :analyse do
    require File.join(File.dirname(__FILE__), '../../config/environment')
    require 'flay'
    require 'flog'
    Project.identify_all
    Project.all.each(&:check_for_modifications_and_analyse)
  end
  
  desc "Schedule analyses using cron"
  task :schedule_analyses do
    exec 'whenever --update-crontab inotegration'
  end
end