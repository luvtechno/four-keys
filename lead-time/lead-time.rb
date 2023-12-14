require 'bundler/setup'

require 'dotenv/load'
require 'rugged'
require 'csv'

require_relative 'repo'
require_relative 'github'

repo_root_dir = ENV['REPO_ROOT_DIR']
repo_owner = ENV['REPO_OWNER']
repo_names = ENV['REPO_NAME'].split(',')
production_branch_name = ENV['PRODUCTION_BRANCH_NAME']

output_file = "#{repo_owner}.csv"
headers = [
  'repository',
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
  repo_names.each do |repo_name|
    repo_dir = "#{repo_root_dir}/#{repo_owner}/#{repo_name}"

    repo = Repo.new(repo_dir: repo_dir, production_branch_name: production_branch_name)
    repo.load_deployment_times

    github = GitHub.new(repo_owner: repo_owner, repo_name: repo_name)
    pull_requests = github.load_pull_requests(debug: false)

    pull_requests.each do |pr|
      created_at = Time.parse(pr.created_at).getlocal
      merged_at = Time.parse(pr.merged_at).getlocal
      deployed_at = repo.deployment_time(oid: pr.merge_commit.oid)
      lead_time = deployed_at ? (deployed_at - created_at) / (60 * 60 * 24) : nil

      csv << [
        repo_name,
        pr.number,
        pr.permalink,
        pr.title,
        pr.author.login,
        pr.base_ref_name,
        created_at.strftime("%Y-%m-%d %H:%M:%S"),
        merged_at&.strftime("%Y-%m-%d %H:%M:%S"),
        pr.merge_commit.oid,
        deployed_at&.strftime("%Y-%m-%d %H:%M:%S"),
        lead_time,
      ]
    end
  end
end

# binding.irb