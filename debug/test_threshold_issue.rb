#!/usr/bin/env ruby
# Test threshold filtering issue in full-text search

require_relative '../config/environment'

puts 'Testing threshold filtering issue...'
puts '=' * 50

query = 'jesus weep death'
threshold = 0.5

puts "Query: '#{query}'"
puts "Threshold: #{threshold}"
puts "Expected: Only results with similarity >= #{threshold}"
puts ""

# Test the search
results = Ragdoll::Document.search_content(query, limit: 10, threshold: threshold)
puts "Results returned: #{results.count}"
puts ""

results.each_with_index do |doc, i|
  similarity = doc.attributes['fulltext_similarity']&.to_f || 0.0
  threshold_met = similarity >= threshold
  status = threshold_met ? '✅' : '❌'
  
  puts "#{i+1}. #{status} #{doc.title}"
  puts "   Similarity: #{similarity.round(3)} (threshold: #{threshold})"
  puts "   Should be filtered: #{!threshold_met ? 'YES' : 'NO'}"
  puts ""
end

# Check if threshold parameter is being used in the method
puts "=" * 50
puts "Checking if threshold parameter is being used..."

# Look at the method signature
method = Ragdoll::Document.method(:search_content)
puts "Method location: #{method.source_location}"

# Test with no threshold
puts ""
puts "Testing with no threshold specified:"
no_threshold_results = Ragdoll::Document.search_content(query, limit: 10)
puts "Results without threshold: #{no_threshold_results.count}"