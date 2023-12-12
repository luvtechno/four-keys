require 'bundler/setup'

require 'dotenv/load'
require 'rugged'

production_branch_name = 'master'
deploy_time_map = Hash.new  # hash [String] => commit time [Time], where hash is git commit hash

repo_dir = ENV['REPO_DIR']
repo = Rugged::Repository.new(repo_dir)
walker = Rugged::Walker.new(repo)

production_branch = repo.branches[production_branch_name]
latest_commit_hash = production_branch.target.oid

walker.push(latest_commit_hash)
puts "#{walker.count} commits in #{production_branch_name} branch"

walker.reset
walker.push(latest_commit_hash)
walker.simplify_first_parent  # traverse only the first parent of each commit
walker.sorting(Rugged::SORT_REVERSE)
walker.each do |production_branch_commit|
  deploy_time = production_branch_commit.time
  deploy_time_map[production_branch_commit.oid] = deploy_time

  commit_hash_list = production_branch_commit.parent_oids
  while !commit_hash_list.empty?
    commit_hash = commit_hash_list.pop
    if deploy_time_map[commit_hash]
      next
    else
      deploy_time_map[commit_hash] = deploy_time
      commit = repo.lookup(commit_hash)
      commit_hash_list += commit.parent_oids
    end
  end
end

binding.irb