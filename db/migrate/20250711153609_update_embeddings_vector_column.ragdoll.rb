# This migration comes from ragdoll (originally 20250220123456)
class UpdateEmbeddingsVectorColumn < ActiveRecord::Migration[8.0]
  def up
    # Skip vector conversion - keep embedding as text for compatibility
    # Add column to track embedding dimensions
    add_column :ragdoll_embeddings, :embedding_dimensions, :integer unless column_exists?(:ragdoll_embeddings, :embedding_dimensions)
    
    # Add index on embedding_dimensions for faster filtering
    add_index :ragdoll_embeddings, :embedding_dimensions unless index_exists?(:ragdoll_embeddings, :embedding_dimensions)
    
    # Add index on model_name and embedding_dimensions combination
    unless index_exists?(:ragdoll_embeddings, [:model_name, :embedding_dimensions])
      add_index :ragdoll_embeddings, [:model_name, :embedding_dimensions], 
                name: 'index_ragdoll_embeddings_on_model_and_dimensions'
    end
  end

  def down
    # Remove the new columns and indexes
    remove_index :ragdoll_embeddings, :embedding_dimensions
    remove_index :ragdoll_embeddings, name: 'index_ragdoll_embeddings_on_model_and_dimensions'
    remove_column :ragdoll_embeddings, :embedding_dimensions
    
    # Restore the original limit (this will fail if there are vectors with different dimensions)
    change_column :ragdoll_embeddings, :embedding, :vector, limit: 1536
  end
end