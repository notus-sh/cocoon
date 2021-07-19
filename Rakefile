# frozen_string_literal: true

## Test suites

# Ruby
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new
task default: :spec

# JavaScript
require 'jasmine'
load 'jasmine/tasks/jasmine.rake'

## Linters

# Ruby
require 'rubocop/rake_task'
RuboCop::RakeTask.new do |task|
  task.options = ['--config', 'config/linters/ruby.yml']
end

# JavaScript
# rubocop:disable Rails/RakeEnvironment
# eslint related tasks does not need to load Rails environment
eslint_args = ['--no-eslintrc', '--config config/linters/js.json']
eslint_path = ['app/assets/**/*.js', 'spec/javascripts/**/*.js', 'spec/dummy/app/assets/**/*.js']

namespace :eslint do
  desc 'Auto-correct eslint offenses'
  task :auto_correct do
    system("yarnpkg run eslint #{(eslint_args + ['--fix']).join(' ')} #{eslint_path.join(' ')}")
  end
end

desc 'Run eslint'
task :eslint do
  system("yarnpkg run eslint #{eslint_args.join(' ')} #{eslint_path.join(' ')}")
end
# rubocop:enable Rails/RakeEnvironment

# Both
namespace :linters do
  desc 'Auto-correct Rubocop and eslint offenses'
  task auto_correct: ['rubocop:auto_correct', 'eslint:auto_correct']
end

desc 'Run Rubocop and eslint'
task linters: %i[rubocop eslint]

## Packaging

# Ruby
require 'bundler/gem_tasks'

# JavaScript
require 'json'

spec = Bundler.load_gemspec('./cocooned.gemspec')
npm_scope = 'notus.sh'

npm_src_dir = './npm'
npm_dest_dir = './dist'
CLOBBER.include 'dist'

assets_dir = './app/assets/'

npm_files = {
  File.join(npm_dest_dir, 'cocooned.js') => File.join(assets_dir, 'javascripts', 'cocooned.js'),
  File.join(npm_dest_dir, 'cocooned.css') => File.join(assets_dir, 'stylesheets', 'cocooned.css'),
  File.join(npm_dest_dir, 'README.md') => File.join(npm_src_dir, 'README.md'),
  File.join(npm_dest_dir, 'LICENSE') => './LICENSE'
}

namespace :npm do
  # rubocop:disable Rails/RakeEnvironment
  # npm related tasks does not need to load Rails environment
  npm_files.each do |dest, src|
    file dest => src do
      cp src, dest
    end
  end

  task :'package-json' do
    contributors = []
    spec.authors.each_with_index do |name, i|
      next if spec.email[i].nil?

      contributors << {
        name: name.dup.force_encoding('UTF-8'),
        email: spec.email[i].dup.force_encoding('UTF-8')
      }
    end

    template = ERB.new(File.read(File.join(npm_src_dir, 'package.json.erb')))
    content = template.result_with_hash(scope: npm_scope, spec: spec, contributors: contributors)
    File.write(File.join(npm_dest_dir, 'package.json'),
               JSON.pretty_generate(JSON.parse(content)))
  end

  desc "Build #{npm_scope}-#{spec.name}-#{spec.version}.tgz into the pkg directory"
  task build: (%i[package-json] + npm_files.keys) do
    system("cd #{npm_dest_dir} && npm pack && mv ./#{npm_scope}-#{spec.name}-#{spec.version}.tgz ../pkg/")
  end

  desc "Build and push #{npm_scope}-#{spec.name}-#{spec.version}.tgz to https://npmjs.org"
  task release: %i[build] do
    system("npm publish ./pkg/#{npm_scope}-#{spec.name}-#{spec.version}.tgz --access public")
  end
  # rubocop:enable Rails/RakeEnvironment
end

desc 'Build packages and push them to their respective repository'
task releases: [:release, 'npm:release']
