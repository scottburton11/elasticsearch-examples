require 'bundler/setup'
require 'elasticsearch'
client = Elasticsearch::Client.new :log => true

require 'georuby'
require 'geo_ruby/shp4r/shp'
shapes = GeoRuby::Shp4r::ShpFile.open("./ZillowNeighborhoods-CA/ZillowNeighborhoods-CA")

require 'csv'
require 'json'
providers = CSV.parse(File.read("../providers.csv"), :headers => true)

require 'pry'

 #<CSV::Row "company_name":"" "geocoded_street_address":"8920 Wilshire Blvd" "geocoded_city_address":"Beverly Hills, CA 90211" "st_asgeojson":"{\"type\":\"Point\",\"coordinates\":[-118.386476833540002,34.066948357020898]}" "geocoded_zip":"90211">

client.transport.perform_request(:delete, "geo") if client.indices.exists(:index => "geo")

puts "Creating index 'geo'"
client.transport.perform_request(:post, "geo", {}, 
  {
    mappings: {
      neighborhood: {
        properties: {
          location: {
            type: 'geo_shape'
          },
          state: {
            type: "string",
            index: 'not_analyzed'
          },
          city: {
            type: "string",
            index: 'not_analyzed'
          },
          name: {
            type: "string",
            index: 'not_analyzed'
          },
          suggested_name: {
            type: "completion",
            index_analyzer: "simple",
            search_analyzer: "simple",
            payloads: true
          }
        }
      }
    }
  }
)

client.transport.perform_request(:delete, "providers") if client.indices.exists(:index => "providers")

puts "Creating index 'providers'"
client.transport.perform_request(:post, "providers", {}, 
  {
    mappings: {
      provider: {
        properties: {
          location: {
            type: 'geo_shape'
          },
          suggested_name: {
            type: "completion",
            index_analyzer: "simple",
            search_analyzer: "simple",
            payloads: true
          }
        }
      }
    }
  }
)


puts "Indexing shapes"
shapes.each do |shape|
  document = {
    :location => {
      :type => "multipolygon",
      :coordinates => shape.geometry.to_coordinates
    },
    :attributes => shape.data.attributes,
    :city => shape.data.attributes["CITY"],
    :state => shape.data.attributes["STATE"],
    :name => shape.data.attributes["NAME"],
    :suggested_name => {
      :input => shape.data.attributes["NAME"].split(/\s/) + [shape.data.attributes["NAME"]],
      :output => shape.data.attributes["NAME"]
    },
    :id => shape.data.attributes["REGIONID"]
  }
  begin
    client.index :index => "geo", :type => "neighborhood", :id => shape.data.attributes["REGIONID"], :body => document
  rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
    next
  end
end

puts "Indexing providers"
providers.each do |provider|
  next unless provider['company_name'] && provider['company_name'].length > 0
  next unless provider['st_asgeojson'] && provider['st_asgeojson'].length > 0
  document = {
    :location => JSON.parse(provider['st_asgeojson']),
    :company_name => provider['company_name'],
    :suggested_name => {
      :input => provider['company_name'].split(/\s/) + [provider['company_name']],
      :output => provider['company_name']
    },
    :street_address => provider['geocoded_street_address'],
    :city_address   => provider['geocoded_city_address'],
    :zip_address    => provider['geocoded_zip']
  }
  begin
    client.index :index => "providers", :type => "provider", :body => document
  rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
    next
  end
end


