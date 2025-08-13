class SearchController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:search]
  
  def index
    # TODO: Implement search tracking
    @recent_searches = []
    @popular_queries = {}
    @filters = {
      document_type: params[:document_type],
      status: params[:status],
      limit: params[:limit]&.to_i || 10,
      threshold: params[:threshold]&.to_f || (Rails.env.development? ? 0.001 : 0.7)  # Much lower threshold for development
    }
    @query = params[:query]
    @search_performed = false
  end
  
  def search
    Rails.logger.debug "🔍 Search called with params: #{params.inspect}"
    @query = params[:query]
    @filters = {
      document_type: params[:document_type],
      status: params[:status],
      limit: params[:limit]&.to_i || 10,
      threshold: params[:threshold]&.to_f || (Rails.env.development? ? 0.001 : 0.7)  # Much lower threshold for development
    }
    Rails.logger.debug "🔍 Query: #{@query.inspect}, Filters: #{@filters.inspect}"
    
    # Initialize data needed for the view sidebar
    # TODO: Implement search tracking
    @recent_searches = []
    @popular_queries = {}
    
    if @query.present?
      begin
        # Check which search types are enabled (default to both if neither param is set)
        use_similarity = params[:use_similarity_search] != 'false'
        use_fulltext = params[:use_fulltext_search] != 'false'
        
        @detailed_results = []
        
        # Perform similarity search if enabled
        if use_similarity
          begin
            search_response = Ragdoll.search(
              query: @query,
              limit: @filters[:limit],
              threshold: @filters[:threshold]
            )
            
            # The search returns a hash with :results and :statistics
            @results = search_response.is_a?(Hash) ? search_response[:results] || [] : []
            @similarity_stats = search_response.is_a?(Hash) ? search_response[:statistics] || {} : {}
            
            # Add similarity search results
            @results.each do |result|
              if result[:embedding_id] && result[:document_id]
                embedding = Ragdoll::Embedding.find(result[:embedding_id])
                document = Ragdoll::Document.find(result[:document_id])
                @detailed_results << {
                  embedding: embedding,
                  document: document,
                  similarity: result[:similarity],
                  content: result[:content],
                  usage_count: embedding.usage_count,
                  last_used: embedding.returned_at,
                  search_type: 'similarity'
                }
              end
            end
            
            # Store threshold info for when no similarity results are found
            @similarity_threshold_used = @filters[:threshold]
            @similarity_search_attempted = true
            
          rescue => e
            Rails.logger.error "Similarity search error: #{e.message}"
            # Continue with fulltext search even if similarity search fails
          end
        end
        
        # Perform full-text search if enabled
        if use_fulltext
          fulltext_results = Ragdoll::Document.search_content(@query, limit: @filters[:limit], threshold: @filters[:threshold])
          
          fulltext_results.each do |document|
            # Avoid duplicates if document was already found in similarity search
            unless @detailed_results.any? { |r| r[:document].id == document.id }
              # Use the fulltext_similarity score from the enhanced search
              fulltext_similarity = document.respond_to?(:fulltext_similarity) ? document.fulltext_similarity.to_f : 0.0
              
              @detailed_results << {
                document: document,
                content: document.metadata&.dig('summary') || document.title || "No summary available",
                search_type: 'fulltext',
                similarity: fulltext_similarity
              }
            end
          end
        end
        
        # Sort results by similarity score if available, otherwise by relevance
        @detailed_results.sort_by! { |r| r[:similarity] ? -r[:similarity] : 0 }
        
        # Save search for analytics
        search_type = case
                     when use_similarity && use_fulltext then 'hybrid'
                     when use_similarity then 'similarity'
                     when use_fulltext then 'fulltext'
                     else 'unknown'
                     end
        
        similarity_results = @detailed_results.select { |r| r[:search_type] == 'similarity' }
        similarities = similarity_results.map { |r| r[:similarity] }.compact
        
        # TODO: Save search for analytics - requires query_embedding generation
        # Currently disabled due to validation requirement for query_embedding
        Rails.logger.debug "🔍 Search analytics saving disabled (requires query embedding generation)"
        
        Rails.logger.debug "🔍 Search completed successfully. Results count: #{@detailed_results.count}"
        @search_performed = true
        
      rescue => e
        Rails.logger.error "🔍 Search error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        @error = e.message
        @search_performed = false
      end
    else
      @search_performed = false
    end
    
    respond_to do |format|
      format.html { render :index }
      format.json { 
        json_response = { results: @detailed_results, error: @error }
        if @similarity_search_attempted && @similarity_stats
          json_response[:similarity_statistics] = {
            threshold_used: @similarity_threshold_used,
            stats: @similarity_stats
          }
        end
        render json: json_response
      }
    end
  end
  
end