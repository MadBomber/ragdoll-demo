#!/usr/bin/env ruby
# Test enhanced fulltext search service

require_relative '../config/environment'

puts "Testing Enhanced Fulltext Search Service"
puts "=" * 50

test_queries = [
  'sin',
  'sins worse',
  'Are Some Sins Worse Than Others',
  'redemption salvation grace',
  'God holy righteous',
  'nephilim sons daughters'
]

test_queries.each do |query|
  puts "\nQuery: '#{query}'"
  puts "-" * 30
  
  begin
    # Test new enhanced search
    enhanced_results = EnhancedFulltextSearchService.search(query, limit: 5)
    puts "Enhanced Fulltext Results: #{enhanced_results.count}"
    
    enhanced_results.each_with_index do |result, i|
      puts "  #{i+1}. #{result[:document].title}"
      puts "     Similarity: #{result[:similarity].round(3)}"
      puts "     Content: #{result[:content][0..100]}..." if result[:content]
    end
    
    if enhanced_results.empty?
      puts "  No results found"
    end
    
    # Compare with original search
    puts "\nOriginal Search Results:"
    original_results = Ragdoll::Document.search_content(query, limit: 5)
    puts "  Count: #{original_results.count}"
    original_results.each_with_index do |doc, i|
      puts "  #{i+1}. #{doc.title}"
    end
    
  rescue => e
    puts "Error: #{e.message}"
    puts e.backtrace.first(3).join("\n")
  end
  
  puts ""
end