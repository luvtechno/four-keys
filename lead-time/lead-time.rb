require 'bundler/setup'

require 'dotenv/load'
require 'rugged'
require 'csv'

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
pull_requests = github.load_pull_requests(debug: false)

output_file = "#{repo_name}.csv"
headers = [
  '#',
  'URL',
  'title',
  'author',
  'baseRefName',
  'createdAt',
  'mergedAt',
  'mergeCommit',
  'deployedAt',
  'leadTime',
]
CSV.open(output_file, 'w', headers: headers, write_headers: true) do |csv|
  pull_requests.each do |pr|
    created_at = Time.parse(pr.created_at).getlocal
    merged_at = Time.parse(pr.merged_at).getlocal
    deployed_at = repo.deployment_time(oid: pr.merge_commit.oid)
    lead_time = deployed_at ? (deployed_at - created_at) / (60 * 60 * 24) : nil

    csv << [
      pr.number,
      pr.permalink,
      pr.title,
      pr.author.login,
      pr.base_ref_name,
      created_at,
      merged_at,
      pr.merge_commit.oid,
      deployed_at,
      lead_time,
    ]
  end
end

# binding.irb