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
    @query = params[:query]
    @filters = {
      document_type: params[:document_type],
      status: params[:status],
      limit: params[:limit]&.to_i || 10,
      threshold: params[:threshold]&.to_f || (Rails.env.development? ? 0.001 : 0.7)  # Much lower threshold for development
    }
    
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
            
            # The search returns a hash with :results
            @results = search_response.is_a?(Hash) ? search_response[:results] || [] : []
            
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
          rescue => e
            Rails.logger.error "Similarity search error: #{e.message}"
            # Continue with fulltext search even if similarity search fails
          end
        end
        
        # Perform full-text search if enabled
        if use_fulltext
          fulltext_results = Ragdoll::Document.search_content(@query, limit: @filters[:limit])
          
          fulltext_results.each do |document|
            # Avoid duplicates if document was already found in similarity search
            unless @detailed_results.any? { |r| r[:document].id == document.id }
              @detailed_results << {
                document: document,
                content: document.summary.presence || "No summary available",
                search_type: 'fulltext',
                similarity: nil
              }
            end
          end
        end
        
        # Sort results by similarity score if available, otherwise by relevance
        @detailed_results.sort_by! { |r| r[:similarity] ? -r[:similarity] : 0 }
        
        # TODO: Save search for analytics when search tracking is implemented
        # if @results.any?
        #   Ragdoll::Search.create!(
        #     query: @query,
        #     search_type: 'semantic',
        #     result_count: @results.count,
        #     model_name: Ragdoll.configuration.embedding_model || 'demo-embedding-model'
        #   )
        # end
        
        @search_performed = true
        
      rescue => e
        @error = e.message
        @search_performed = false
      end
    else
      @search_performed = false
    end
    
    respond_to do |format|
      format.html { render :index }
      format.json { render json: { results: @detailed_results, error: @error } }
    end
  end
  
  def analytics
    # TODO: Implement search tracking and analytics
    @search_stats = {
      total_searches: 0,
      unique_queries: 0,
      searches_today: 0,
      searches_this_week: 0,
      average_results: 0,
      average_similarity: 0.82 # Default value
    }
    
    @top_queries = {}
    @search_trends = {}
    @top_documents = {}
    @similarity_distribution = {
      "0.9-1.0" => 25,
      "0.8-0.9" => 45,
      "0.7-0.8" => 30,
      "0.6-0.7" => 15,
      "0.5-0.6" => 5
    }
  end
end