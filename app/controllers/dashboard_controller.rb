class DashboardController < ApplicationController
  def index
    @stats = {
      total_documents: Ragdoll::Document.count,
      processed_documents: Ragdoll::Document.where(status: 'processed').count,
      failed_documents: Ragdoll::Document.where(status: 'failed').count,
      pending_documents: Ragdoll::Document.where(status: 'pending').count,
      total_embeddings: Ragdoll::Embedding.count,
      total_searches: Ragdoll::Search.count,
      recent_searches: Ragdoll::Search.includes(:document).order(created_at: :desc).limit(5)
    }
    
    @document_types = Ragdoll::Document.group(:document_type).count
    @recent_documents = Ragdoll::Document.order(created_at: :desc).limit(10)
    
    # Usage analytics
    @top_searched_documents = Ragdoll::Embedding
      .joins(:document)
      .group('ragdoll_documents.title')
      .order('SUM(ragdoll_embeddings.usage_count) DESC')
      .limit(5)
      .sum(:usage_count)
  end
  
  def analytics
    @search_analytics = {
      total_searches: Ragdoll::Search.count,
      searches_today: Ragdoll::Search.where('created_at > ?', 1.day.ago).count,
      searches_this_week: Ragdoll::Search.where('created_at > ?', 1.week.ago).count,
      searches_this_month: Ragdoll::Search.where('created_at > ?', 1.month.ago).count
    }
    
    @popular_queries = Ragdoll::Search
      .group(:query)
      .order('COUNT(*) DESC')
      .limit(10)
      .count
    
    @search_performance = Ragdoll::Search
      .where('created_at > ?', 1.week.ago)
      .group('DATE(created_at)')
      .count
    
    @embedding_usage = Ragdoll::Embedding
      .joins(:document)
      .group('ragdoll_documents.title')
      .order('SUM(ragdoll_embeddings.usage_count) DESC')
      .limit(10)
      .sum(:usage_count)
  end
end