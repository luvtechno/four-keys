require 'bundler/setup'

require 'dotenv/load'
require 'rugged'

production_branch_name = 'master'
deploy_time_hash = Hash.new  # hash String => Time, where hash is git commit hash in the production branch

repo_dir = ENV['REPO_DIR']
repo = Rugged::Repository.new(repo_dir)
walker = Rugged::Walker.new(repo)

production_branch = repo.branches[production_branch_name]
latest_commit_hash = production_branch.target.oid

walker.push(latest_commit_hash)

binding.irb