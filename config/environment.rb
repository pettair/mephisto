# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.class_eval do
  def load_plugins
    find_plugins(configuration.plugin_paths).sort.each { |path| load_plugin path }
    $LOAD_PATH.uniq!
  end
end

require 'RedCloth-3.0.4/lib/redcloth'
Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here
  
  # Skip frameworks you're not going to use
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for your own custom dirs
  config.load_paths += %W( #{RAILS_ROOT}/app/cachers )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake create_sessions_table')
  config.action_controller.session_store = :active_record_store

  # Enable page/fragment caching by setting a file-based store
  # (remember to create the caching directory and make it readable to the application)
  # config.action_controller.fragment_cache_store = :file_store, "#{RAILS_ROOT}/cache"

  # Activate observers that should always be running
  # config.active_record.observers = [:article_observer]

  # Make Active Record use UTC-base instead of local time
  config.active_record.default_timezone = :utc
  
  # Use Active Record's schema dumper instead of SQL when creating the test database
  # (enables use of different database adapters for development and test environments)
  config.active_record.schema_format = :ruby

  # See Rails::Configuration for more options
end

# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Include your application configuration below
require 'tzinfo'
require 'time_ext'
require 'zip/zipfilesystem'
Liquid::Template.register_filter(Mephisto::Liquid::Filters)
Liquid::Template.register_tag('textile',        Mephisto::Liquid::Textile)
Liquid::Template.register_tag('commentform',    Mephisto::Liquid::CommentForm)
Liquid::Template.register_tag('pagenavigation', Mephisto::Liquid::PageNavigation)
Liquid::Template.register_tag('head',           Mephisto::Liquid::Head)
FilteredColumn.constant_filters << :macro_filter

ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.update \
  :standard  => '%B %d, %Y @ %I:%M%p',
  :stub      => '%B %d', # XXX what is the meaning of stub in this context?
  :time_only => '%I:%M %p',
  :plain     => '%B %d %I:%M %p'

# Time.now.to_ordinalized_s :long
# => "February 28th, 2006 21:10"
module ActiveSupport::CoreExtensions::Time::Conversions
  def to_ordinalized_s(format = :default)
    format = ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS[format] 
    return to_default_s if format.nil?
    # XXX should we convert this Time object to Site timezone here?  (if its in UTC timezone)  but this seems something that is not a concern for this Time object :/
    strftime(format.gsub(/%d/, '_%d_')).gsub(/_(\d+)_/) { |s| s.to_i.ordinalize }
  end
end

# http://rails.techno-weenie.net/tip/2005/12/23/make_fixtures
ActiveRecord::Base.class_eval do
  # Write a fixture file for testing
  def self.to_fixture(fixture_path = nil)
    File.open(File.expand_path(fixture_path || "test/fixtures/#{table_name}.yml", RAILS_ROOT), 'w') do |out|
      YAML.dump find(:all).inject({}) { |hsh, record| hsh.merge(record.id => record.attributes) }, out
    end
  end
end

Akismet.class_eval do
  cattr_accessor :api_key
  cattr_accessor :blog
end

Akismet.api_key = ActiveRecord::Base.configurations[RAILS_ENV]['akismet_api_key']
Akismet.blog    = ActiveRecord::Base.configurations[RAILS_ENV]['akismet_blog']
