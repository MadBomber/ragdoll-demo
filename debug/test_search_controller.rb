#!/usr/bin/env ruby
# Test search controller logic directly

require_relative '../config/environment'

puts "Testing search functionality directly..."
puts "=" * 50

# Test 1: Direct search calls
query = "Are Some Sins Worse Than Others?"
puts "Query: #{query}"
puts ""

# Test similarity search
puts "1. Testing Ragdoll.search:"
begin
  result = Ragdoll.search(query: query, limit: 5, threshold: 0.001)
  puts "   Result type: #{result.class}"
  puts "   Results count: #{result[:results]&.count || 'N/A'}"
  puts "   First result: #{result[:results]&.first&.dig(:document_title) || 'N/A'}"
rescue => e
  puts "   Error: #{e.message}"
end
puts ""

# Test full-text search
puts "2. Testing Document.search_content:"
begin
  fulltext_results = Ragdoll::Document.search_content(query, limit: 5)
  puts "   Results count: #{fulltext_results.count}"
  puts "   First result: #{fulltext_results.first&.title || 'N/A'}"
rescue => e
  puts "   Error: #{e.message}"
end
puts ""

# Test controller logic simulation
puts "3. Testing controller logic:"
begin
  # Simulate controller parameters
  params = {
    'query' => query,
    'use_similarity_search' => 'true',
    'use_fulltext_search' => 'true',
    'limit' => '5',
    'threshold' => '0.001'
  }
  
  query_param = params['query']
  filters = {
    limit: params['limit']&.to_i || 10,
    threshold: params['threshold']&.to_f || 0.001
  }
  
  puts "   Query present: #{query_param.present?}"
  puts "   Filters: #{filters}"
  
  detailed_results = []
  
  # Similarity search
  use_similarity = params['use_similarity_search'] != 'false'
  if use_similarity
    puts "   Running similarity search..."
    search_response = Ragdoll.search(
      query: query_param,
      limit: filters[:limit],
      threshold: filters[:threshold]
    )
    
    results = search_response.is_a?(Hash) ? search_response[:results] || [] : []
    puts "   Similarity results: #{results.count}"
    
    results.each do |result|
      if result[:embedding_id] && result[:document_id]
        embedding = Ragdoll::Embedding.find(result[:embedding_id])
        document = Ragdoll::Document.find(result[:document_id])
        detailed_results << {
          embedding: embedding,
          document: document,
          similarity: result[:similarity],
          content: result[:content],
          search_type: 'similarity'
        }
      end
    end
  end
  
  # Full-text search
  use_fulltext = params['use_fulltext_search'] != 'false'
  if use_fulltext
    puts "   Running full-text search..."
    fulltext_results = Ragdoll::Document.search_content(query_param, limit: filters[:limit])
    puts "   Full-text results: #{fulltext_results.count}"
    
    fulltext_results.each do |document|
      unless detailed_results.any? { |r| r[:document].id == document.id }
        detailed_results << {
          document: document,
          content: document.summary.presence || "No summary available",
          search_type: 'fulltext',
          similarity: nil
        }
      end
    end
  end
  
  puts "   Total combined results: #{detailed_results.count}"
  
rescue => e
  puts "   Error in controller logic: #{e.message}"
  puts "   #{e.backtrace.first(3).join("\n   ")}"
end

puts "=" * 50
puts "Test completed."