require 'bundler/setup'

require 'dotenv/load'
require 'rugged'

require_relative 'repo'

repo_dir = ENV['REPO_DIR']
production_branch_name = ENV['PRODUCTION_BRANCH_NAME']

repo = Repo.new(repo_dir: repo_dir, production_branch_name: production_branch_name)
repo.load_deployment_times

binding.irb