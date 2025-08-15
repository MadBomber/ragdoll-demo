#!/usr/bin/env ruby
# Verify that web interface search is working with new enhanced functionality

require_relative '../config/environment'

puts "Verifying Web Interface Search Integration"
puts "=" * 50

# Simulate the controller search logic with the exact query you used
query = "when did jesus cry?"
puts "Testing query: #{query}"
puts ""

# Simulate controller parameters
use_similarity = false  # Only full-text search
use_fulltext = true

detailed_results = []

begin
  if use_fulltext
    puts "Running full-text search..."
    fulltext_results = Ragdoll::Document.search_content(query, limit: 10)
    
    puts "Full-text results: #{fulltext_results.count}"
    
    fulltext_results.each do |document|
      # Use the fulltext_similarity score from the enhanced search
      fulltext_similarity = document.respond_to?(:fulltext_similarity) ? 
                           document.fulltext_similarity.to_f : 
                           document.attributes['fulltext_similarity']&.to_f || 0.0
      
      detailed_results << {
        document: document,
        content: document.metadata&.dig('summary') || document.title || "No summary available",
        search_type: 'fulltext',
        similarity: fulltext_similarity
      }
    end
  end
  
  # Sort results by similarity score (highest first)
  detailed_results.sort_by! { |r| r[:similarity] ? -r[:similarity] : 0 }
  
  puts ""
  puts "Final combined results: #{detailed_results.count}"
  puts "=" * 30
  
  detailed_results.each_with_index do |result, i|
    puts "#{i+1}. #{result[:document].title}"
    puts "   Type: #{result[:search_type]}"
    puts "   Similarity: #{result[:similarity].round(3)} (#{(result[:similarity] * 100).round(1)}% match)"
    puts "   Content: #{result[:content][0..100]}..." if result[:content]
    puts ""
  end
  
  if detailed_results.empty?
    puts "❌ No results found - this would show 'No results found' message on web interface"
  else
    puts "✅ Search is working correctly - web interface should show these #{detailed_results.count} results"
  end
  
rescue => e
  puts "❌ Error in search: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end