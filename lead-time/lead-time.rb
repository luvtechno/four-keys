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


QUERY = GitHub::Client.parse <<-'GRAPHQL'
query($owner: String!, $name: String!, $after: String) {
  repository(owner: $owner, name: $name) {
    pullRequests(first: 100, states: [MERGED], orderBy: {field: UPDATED_AT, direction: DESC}, after: $after) {
      edges {
        cursor
        node {
          number
          permalink
          title
          author {
            login
          }
          baseRefName
          createdAt
          closed
          closedAt
          merged
          mergedAt
          mergeCommit {
            oid
          }
        }
      }
    }
  }
}
GRAPHQL


pull_requests = []
after = nil

loop do
  variables = {
    owner: repo_owner,
    name: repo_name,
    after: after,
  }
  response = GitHub::Client.query(QUERY, variables: variables, context: {})

  new_pull_requests = response.data.repository.pull_requests.edges.map(&:node)
  break if new_pull_requests.empty?
  pull_requests += new_pull_requests
  after = response.data.repository.pull_requests.edges.last.cursor
  puts "#{pull_requests.size} #{new_pull_requests.size} #{after}"
end

binding.irb