require 'bundler/setup'
require 'sinatra'
require 'elasticsearch'
require 'json'
require 'pry'

helpers do
  def search_client
    @search_client ||= Elasticsearch::Client.new :log => true
  end
end

get "/" do
  erb :index
end

get "/shapes" do
  coordinates = params[:coordinates].split(",")
  coordinates = [[coordinates[3], coordinates[2]], [coordinates[1], coordinates[0]]]
  results = search_client.search index: 'geo', body: 
    {
      query: {
        filtered: {
          filter: {
            geo_shape: {
              location: {
                shape: {
                  type: "envelope", coordinates: coordinates 
                }
              }
            }
          }
        }
      },
      size: 500
    }
  hits = results['hits']['hits'].map{|hit| hit["_source"]}
  hits.to_json
end