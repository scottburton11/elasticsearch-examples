require 'bundler/setup'
require 'elasticsearch'
require 'pry'
client = Elasticsearch::Client.new :log => true

# coordinates = [[-117.02084350585938, 34.35590615959198], [-118.99288940429688, 33.93424357136147]]
coordinates = [[-116, 38], [-119, 33]]

results = client.search index: 'geo', body: {query: {filtered: {filter: {geo_shape: {location: {shape: {type: "envelope", coordinates: coordinates }}}}}}}
binding.pry