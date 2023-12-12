require 'bundler/setup'

require 'dotenv/load'
require 'rugged'

require_relative 'repo'
require_relative 'github'

repo_dir = ENV['REPO_DIR']
production_branch_name = ENV['PRODUCTION_BRANCH_NAME']

repo = Repo.new(repo_dir: repo_dir, production_branch_name: production_branch_name)
repo.load_deployment_times


client_context = {}

UserProfileQuery = GitHub::Client.parse <<-'GRAPHQL'
query {
  viewer {
    login
  }
}
GRAPHQL

response = GitHub::Client.query(UserProfileQuery, variables: {}, context: client_context)


binding.irb