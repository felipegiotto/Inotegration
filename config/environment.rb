# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  config.gem 'flog'
  config.gem 'flay'
  config.gem 'roodi'
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'Brasilia'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
end

class Flay
  def report_string prune = nil
    out = ""
    out += "Pontuação total (menor é melhor) = #{self.total}\n"

    count = 0
    masses.sort_by { |h,m| [-m, hashes[h].first.file] }.each do |hash, mass|
      nodes = hashes[hash]
      next unless nodes.first.first == prune if prune
      out += "\n"

      same = identical[hash]
      node = nodes.first
      n = nodes.size
      match, bonus = if same then
                       ["IDÊNTICO", "*#{n}"]
                     else
                       ["Similar",   ""]
                     end

      count += 1
      out += "%d) Código %s encontrado em %p (duplicação%s = %d)\n" %
        [count, match, node.first, bonus, mass]

      nodes.each_with_index do |node, i|
        if option[:verbose] then
          c = (?A + i).chr
          out += "  #{c}: #{node.file}:#{node.line}\n"
        else
          out += "  #{node.file}:#{node.line}\n"
        end
      end

      if option[:verbose] then
        out += "\m"
        r2r = Ruby2Ruby.new
        out += n_way_diff(*nodes.map { |s| r2r.process(s.deep_clone) })
        out += "\n"
      end
    end
    out
  end
end