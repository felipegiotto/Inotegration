module InotegrationTests

  SPEC_TESTS = ['Spec', Result::FAIL, <<-SPEC_TESTS
      str = `rake spec RAILS_ENV=test`
      if !str.include? 'Finished'
        nil
      elsif str.include?('0 failures')
        str
      else
        raise str
      end
SPEC_TESTS
]

  UNITS_TESTS = ['Unit Tests', Result::FAIL, <<-UNIT_TESTS
      str = `rake test:units`
      if !str.include? 'Finished'
        nil
      elsif str.include?('0 failures, 0 errors')
        str
      else
        raise str
      end
UNIT_TESTS
]

  FUNCTIONAL_TESTS = ['Functional Tests', Result::FAIL, <<-FUNCTIONAL_TESTS
      str = `rake test:functionals`
      if !str.include? 'Finished'
        nil
      elsif str.include?('0 failures, 0 errors')
        str
      else
        raise str
      end
FUNCTIONAL_TESTS
]

  FLOG_COMPLEXITY = ['Code Complexity (Flog)', Result::WARNING, <<-FLOG_COMPLEXITY
      flog = Flog.new
      flog.flog_files folder_names_to_analyse
      threshold = inotegration_config['MaximumFlogComplexity'].to_i

      bad_methods = flog.totals.select do |name, score|
        score > threshold
      end

      if bad_methods.empty?
        "No method found with complexity > \#{threshold}.\nTo change this limit, check README file."
      else
        bad_methods = bad_methods.sort { |a,b| a[1] <=> b[1] }.collect do |name, score|
          "%8.1f: %s" % [score, name]
        end
        raise "\#{bad_methods.length} method(s) with complexity > \#{threshold}:\n\#{bad_methods.join("\n")}.\nTo change this limit, check README file."
      end
FLOG_COMPLEXITY
]

  FLAY_DUPLICATION = ['Code Duplication', Result::WARNING, <<-FLAY_DUPLICATION
      threshold = inotegration_config['MaximumFlayThreshold'].to_i
      flay = Flay.new({:fuzzy => false, :verbose => false, :mass => threshold})
      flay.process(*Flay.expand_dirs_to_files(folder_names_to_analyse))

      if flay.masses.empty?
        "No code block with duplication > \#{threshold}.\nTo change this limit, check README file."
      else
        raise "\#{flay.masses.size} code block(s) with duplicated data with threshold \#{threshold}:\n\#{flay.report_string}.\nTo change this limit, check README file."
      end
FLAY_DUPLICATION
]

  ROODI_CODE_QUALITY = ['Code Quality (Roodi)', Result::WARNING, <<-ROODI_CODE_QUALITY
      if inotegration_config['RoodiConfig'].blank?
        str = `roodi app/**/*.rb lib/**/*.rb`
      else
        File.open 'tmp/roodi.yml', 'w' do |f|
          f.puts inotegration_config['RoodiConfig'].to_yaml
        end
        str = `roodi -config=tmp/roodi.yml \#{files_to_analyse}`
      end
      if str.include?('Found 0 errors')
        str
      else
        raise str
      end
ROODI_CODE_QUALITY
]

  REEK_CODE_QUALITY = ['Code Quality (Reek)', Result::WARNING, <<-REEK_CODE_QUALITY
      if inotegration_config['ReekConfig'].blank?
        File.delete 'site.reek' if File.exists? 'site.reek'
      else
        File.open 'site.reek', 'w' do |f|
          f.puts inotegration_config['ReekConfig'].to_yaml
        end
      end
      begin
        str = `reek \#{files_to_analyse}`
        if str.blank?
          "No bad smells found in this project"
        else
          raise str
        end
      ensure
        File.delete 'site.reek' if File.exists? 'site.reek'
      end
REEK_CODE_QUALITY
]

end