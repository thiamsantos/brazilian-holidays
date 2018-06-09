# frozen_string_literal: true

require 'rubocop/rake_task'
require 'rspec/core/rake_task'
require 'standalone_migrations'

task default: %w[spec lint]

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new(:lint)
StandaloneMigrations::Tasks.load_tasks

task :server do
  system('bin/rackup config.ru')
end
