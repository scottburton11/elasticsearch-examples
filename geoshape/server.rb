require 'bundler/setup'
require 'sinatra'
require 'elasticsearch'
require 'active_support/concern'
require 'json'
require 'pry'
require 'pry-debugger'

module Searchable
  extend ActiveSupport::Concern

  module ClassMethods
    def search(q)
      new.search(q)
    end

    def suggest(q)
      new.suggest(q)
    end
  end

  def search(q)
    client.search :q => q, :type => self.class.name.downcase
  end

  def suggest(q)
    client.suggest(
      :index => self.class.name.downcase + "s", 
      :body => {
        :provider => {
          :text => q, :completion => {
            :field => "suggested_name"
          }
        }
      }
    )
  end

  def client
    @client ||= Elasticsearch::Client.new :log => true
  end
end

class Provider
  include Searchable
end

class Geo
  include Searchable
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

get "/search" do
  Provider.search(params[:q]).to_json
end

get "/suggest" do
  Provider.suggest(params[:q]).to_json
end