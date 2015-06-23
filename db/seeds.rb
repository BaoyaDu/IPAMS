# encoding: utf-8

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
require_relative 'populate_table'
include PopulateTable

# Stops rake db:seed in the production environment
if (ENV["RAILS_ENV"] == "production")
  puts "Running rake db:seed in the production environment is forbidden!"
else
  run
end
