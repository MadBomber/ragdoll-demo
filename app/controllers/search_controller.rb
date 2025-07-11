class SearchController < ApplicationController
  def index
    @recent_searches = Ragdoll::Search.order(created_at: :desc).limit(10)
    @popular_queries = Ragdoll::Search.group(:query).order('COUNT(*) DESC').limit(10).count
  end
  
  def search
    @query = params[:query]
    @filters = {
      document_type: params[:document_type],
      status: params[:status],
      limit: params[:limit]&.to_i || 10,
      threshold: params[:threshold]&.to_f || 0.7
    }
    
    if @query.present?
      begin
        client = Ragdoll::Client.new
        
        # Perform search
        search_options = {
          limit: @filters[:limit],
          threshold: @filters[:threshold],
          use_usage_ranking: params[:use_usage_ranking] == 'true'
        }
        
        @results = client.search(@query, **search_options)
        
        # Get detailed results with documents
        @detailed_results = @results.map do |result|
          embedding = Ragdoll::Embedding.find(result[:embedding_id])
          {
            embedding: embedding,
            document: embedding.document,
            similarity: result[:similarity],
            content: result[:content],
            usage_count: embedding.usage_count,
            last_used: embedding.returned_at
          }
        end
        
        # Save search for analytics
        if @results.any?
          first_result = @results.first
          embedding = Ragdoll::Embedding.find(first_result[:embedding_id])
          
          Ragdoll::Search.create!(
            query: @query,
            search_type: 'semantic',
            result_count: @results.count,
            model_name: Ragdoll.configuration.embedding_model
          )
        end
        
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
    @search_stats = {
      total_searches: Ragdoll::Search.count,
      unique_queries: Ragdoll::Search.distinct.count(:query),
      searches_today: Ragdoll::Search.where('created_at > ?', 1.day.ago).count,
      searches_this_week: Ragdoll::Search.where('created_at > ?', 1.week.ago).count,
      average_results: Ragdoll::Search.average(:result_count)&.round(3) || 0
    }
    
    @top_queries = Ragdoll::Search
      .group(:query)
      .order('COUNT(*) DESC')
      .limit(20)
      .count
    
    @search_trends = Ragdoll::Search
      .where('created_at > ?', 30.days.ago)
      .group('DATE(created_at)')
      .count
    
    # Note: Search model doesn't have document association
    # This would need to be implemented differently with proper associations
    @top_documents = {}
    
    # Note: Search model doesn't have similarity_score field
    # This would need to be implemented differently with proper schema
    @similarity_distribution = {}
  end
end