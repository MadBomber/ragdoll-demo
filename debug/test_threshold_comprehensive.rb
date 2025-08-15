#!/usr/bin/env ruby
# Comprehensive test of threshold filtering in full-text search

require_relative '../config/environment'

puts "Comprehensive Threshold Filtering Test"
puts "=" * 50

query = 'jesus weep death'
puts "Query: '#{query}'"
puts "Expected similarity scores: 'jesus weep' = 0.667, 'jesus' only = 0.333"
puts ""

test_thresholds = [0.0, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 1.0]

test_thresholds.each do |threshold|
  puts "Threshold: #{threshold}"
  puts "-" * 20
  
  begin
    results = Ragdoll::Document.search_content(query, limit: 10, threshold: threshold)
    puts "Results: #{results.count}"
    
    results.each_with_index do |doc, i|
      similarity = doc.attributes['fulltext_similarity']&.to_f || 0.0
      puts "  #{i+1}. #{doc.title[0..60]}..."
      puts "     Similarity: #{similarity.round(3)} (#{similarity >= threshold ? 'PASS' : 'FAIL'})"
    end
    
    if results.empty?
      puts "  No results (correctly filtered)"
    end
    
  rescue => e
    puts "  Error: #{e.message}"
  end
  
  puts ""
end

puts "Test Analysis:"
puts "=" * 30
puts "✅ Threshold 0.0-0.3: Should return 6 results (all documents with any word match)"
puts "✅ Threshold 0.4-0.6: Should return 1 result (only 'jesus weep' document with 0.667)"  
puts "✅ Threshold 0.7+: Should return 0 results (no document meets this threshold)"
puts ""
puts "The fix is working correctly if results are properly filtered at each threshold!"