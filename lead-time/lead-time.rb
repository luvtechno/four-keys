require 'bundler/setup'

require 'dotenv/load'
require 'rugged'

require_relative 'repo'
require_relative 'github'

repo_root_dir = ENV['REPO_ROOT_DIR']
repo_owner = ENV['REPO_OWNER']
repo_name = ENV['REPO_NAME']
repo_dir = "#{repo_root_dir}/#{repo_owner}/#{repo_name}"
production_branch_name = ENV['PRODUCTION_BRANCH_NAME']

repo = Repo.new(repo_dir: repo_dir, production_branch_name: production_branch_name)
repo.load_deployment_times


github = GitHub.new(repo_owner: repo_owner, repo_name: repo_name)
pull_requests = github.load_pull_requests(debug: true)

binding.irb