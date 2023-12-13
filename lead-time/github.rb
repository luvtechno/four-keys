require "graphql/client"
require "graphql/client/http"

class GitHub
  HTTPAdapter = GraphQL::Client::HTTP.new("https://api.github.com/graphql") do
    def headers(context)
      token = context[:access_token] || ENV['GITHUB_ACCESS_TOKEN']

      {
        "Authorization" => "Bearer #{token}"
      }
    end
  end

  Schema = GraphQL::Client.load_schema(HTTPAdapter)
  Client = GraphQL::Client.new(
    schema: Schema,
    execute: HTTPAdapter,
  )

  # https://docs.github.com/en/graphql/overview/explorer
  QUERY = GitHub::Client.parse <<~'GRAPHQL'
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

  def initialize(repo_owner:, repo_name:)
    @repo_owner = repo_owner
    @repo_name = repo_name
  end

  def load_pull_requests(debug: false)
    pull_requests = []
    after = nil

    loop do
      variables = {
        owner: @repo_owner,
        name: @repo_name,
        after: after,
      }
      response = Client.query(QUERY, variables: variables, context: {})

      new_pull_requests = response.data.repository.pull_requests.edges.map(&:node)
      break if new_pull_requests.empty?
      pull_requests += new_pull_requests
      after = response.data.repository.pull_requests.edges.last.cursor

      puts "#{pull_requests.size} #{new_pull_requests.size} #{after}"

      break if debug
    end

    pull_requests
  end

end