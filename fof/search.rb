require 'bundler/setup'

Bundler.require

client = Elasticsearch::Client.new :log => true

binding.pry