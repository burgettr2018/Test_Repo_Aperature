source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.1'
# Use sqlite3 as the database for Active Record
gem 'sqlite3'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
#gem 'unicorn'
gem 'thin'
# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  gem 'rspec'
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'database_cleaner'
  gem 'shoulda-matchers', '~> 3.1', '>= 3.1.1'

  gem 'timecop'
  gem 'test_after_commit', :group => :test

  gem 'simplecov', :require => false
  gem "brakeman", :require => false

	gem "webmock"

  gem 'rack-mini-profiler'

end

# Access an IRB console on exception pages or by using <%= console %> in views
gem 'web-console', '~> 2.0', group: :development

gem 'kaminari'

gem 'bootstrap-sass', '~> 3.3.4'
gem 'simple_form'
gem 'bootstrap-generators', '~> 3.3.4'
gem 'devise'
gem 'doorkeeper', '~> 4.3'
gem 'font-awesome-sass', '~> 4.7.0'
gem 'rails_admin'
gem "pundit"
gem "oauth2"
gem 'has_secure_token'
#gem 'rocket_pants', '~> 1.0'
gem 'dotenv-rails', :groups => [:development, :test]
gem 'pg'
gem 'tzinfo-data'

gem 'newrelic_rpm'

gem 'omniauth-saml'
gem 'data_migrate'
gem 'validate_url'
gem 'mechanize'
gem 'savon', '~> 2.0'
gem 'rubyntlm'
gem 'wannabe_bool'

gem 'ruby-saml-idp', git: "https://github.com/owenscorning/ruby-saml-idp.git", branch: "master"
gem 'active_model_serializers', '~> 0.10.0'

gem 'delayed_job_active_record'
gem 'whenever', :require => false
gem 'httparty'
gem 'nilify_blanks'
gem 'mjml-rails', '~>4.2.4'
gem 'schema_plus_pg_indexes'
gem 'jwt'
gem 'aws-sdk-kms'
gem 'flipper', '~>0.10.2'
gem 'flipper-active_record', '~>0.10.2'
gem 'retriable', '~> 3.1'
gem 'active_model-errors_details'

oc_common_version = 'v0.0.57'
if ENV["RAILS_ENV"] == "production"
  gem 'owenscorning-web_common', :git => "https://#{ENV['GITHUB_TOKEN']}:x-oauth-basic@github.com/owenscorning/owenscorning-web_common.git", :tag => oc_common_version
else
  gem 'owenscorning-web_common', :git => 'git@github.com:owenscorning/owenscorning-web_common.git', :tag => oc_common_version
end

gem 'rack-cors', :require => 'rack/cors'
gem 'hashdiff'
