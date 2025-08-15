#!/usr/bin/env ruby
# Test the updated fulltext search with OR logic and similarity scoring

require_relative '../config/environment'

puts "Testing Updated Fulltext Search with OR Logic and Similarity Scoring"
puts "=" * 70

test_queries = [
  'sin',
  'sins worse',  
  'Are Some Sins Worse Than Others',
  'redemption salvation grace',
  'God holy righteous',
  'nephilim sons daughters',
  'crossway articles',
  'genesis man'
]

test_queries.each do |query|
  puts "\nQuery: '#{query}'"
  puts "Words: #{query.downcase.split(/\s+/).map(&:strip).reject(&:blank?).inspect}"
  puts "-" * 50
  
  begin
    # Test the updated search_content method
    results = Ragdoll::Document.search_content(query, limit: 5)
    puts "Results: #{results.count}"
    
    if results.any?
      results.each_with_index do |doc, i|
        similarity = doc.respond_to?(:fulltext_similarity) ? doc.fulltext_similarity.to_f : 0.0
        puts "  #{i+1}. #{doc.title}"
        puts "     Similarity: #{similarity.round(3)} (#{(similarity * 100).round(1)}%)"
        
        # Show which words likely matched by checking title
        title_words = doc.title.downcase.split(/\s+/)
        query_words = query.downcase.split(/\s+/)
        matched_words = query_words & title_words
        
        if matched_words.any?
          puts "     Title matches: #{matched_words.join(', ')}"
        end
      end
    else
      puts "  No results found"
    end
    
  rescue => e
    puts "Error: #{e.message}"
    puts e.backtrace.first(3).join("\n")
  end
  
  puts ""
end

puts "\nTesting Behavior Examples:"
puts "=" * 40

# Test specific scenarios
puts "\n1. Single word query:"
results = Ragdoll::Document.search_content('sin', limit: 3)
puts "Query 'sin' -> #{results.count} results"
results.each { |r| puts "   #{r.fulltext_similarity.to_f.round(3)}: #{r.title}" }

puts "\n2. Two word query (both should match some documents):"
results = Ragdoll::Document.search_content('sins worse', limit: 3)  
puts "Query 'sins worse' -> #{results.count} results"
results.each { |r| puts "   #{r.fulltext_similarity.to_f.round(3)}: #{r.title}" }

puts "\n3. Many word query (fewer matches expected):"
results = Ragdoll::Document.search_content('redemption salvation grace mercy', limit: 3)
puts "Query 'redemption salvation grace mercy' -> #{results.count} results"
results.each { |r| puts "   #{r.fulltext_similarity.to_f.round(3)}: #{r.title}" }