require 'bundler/setup'

Bundler.require

providers = JSON.parse(File.read("./providers.json"))

client = Elasticsearch::Client.new :log => true

providers.each do |provider|
  # `curl -XPUT 'http://localhost:9200/fof_1/providers/#{provider["id"]}' -d '#{provider}'`
  client.index :index => "fof_1", :type => "provider", :id => provider['id'], :body => provider
end