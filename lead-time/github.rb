require "graphql/client"
require "graphql/client/http"

module GitHub
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
end