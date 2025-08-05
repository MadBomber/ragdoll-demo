class DashboardController < ApplicationController
  def index
    @stats = {
      total_documents: Ragdoll::Document.count,
      processed_documents: Ragdoll::Document.where(status: 'processed').count,
      failed_documents: Ragdoll::Document.where(status: 'failed').count,
      pending_documents: Ragdoll::Document.where(status: 'pending').count,
      total_embeddings: Ragdoll::Embedding.count,
      total_searches: 0,  # Search tracking not yet implemented
      recent_searches: []  # Search tracking not yet implemented
    }
    
    @document_types = Ragdoll::Document.group(:document_type).count
    @recent_documents = Ragdoll::Document.order(created_at: :desc).limit(10)
    
    # Usage analytics - join through embeddable (Content) to get to documents
    @top_searched_documents = Ragdoll::Embedding
      .joins("JOIN ragdoll_contents ON ragdoll_contents.id = ragdoll_embeddings.embeddable_id")
      .joins("JOIN ragdoll_documents ON ragdoll_documents.id = ragdoll_contents.document_id")
      .group('ragdoll_documents.title')
      .order(Arel.sql('SUM(ragdoll_embeddings.usage_count) DESC'))
      .limit(5)
      .sum(:usage_count)
  end
  
  def analytics
    @search_analytics = {
      total_searches: 0,  # Search tracking not yet implemented
      searches_today: 0,
      searches_this_week: 0,
      searches_this_month: 0,
      average_similarity: 0.85 # Default value until proper calculation is implemented
    }
    
    @popular_queries = {}  # Search tracking not yet implemented
    
    @search_performance = {}  # Search tracking not yet implemented
    
    @embedding_usage = Ragdoll::Embedding
      .joins("JOIN ragdoll_contents ON ragdoll_contents.id = ragdoll_embeddings.embeddable_id")
      .joins("JOIN ragdoll_documents ON ragdoll_documents.id = ragdoll_contents.document_id")
      .group('ragdoll_documents.title')
      .order(Arel.sql('SUM(ragdoll_embeddings.usage_count) DESC'))
      .limit(10)
      .sum(:usage_count)
  end
end