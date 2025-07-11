# This migration comes from ragdoll (originally 20250219123456)
class CreateRagdollEmbeddings < ActiveRecord::Migration[8.0]
  def change
    create_table :ragdoll_embeddings do |t|
      t.references :document, null: false, foreign_key: { to_table: :ragdoll_documents }
      t.text :content, null: false
      # Use text column for embedding data - can be converted to vector later when pgvector is available
      t.text :embedding
      t.string :model_name
      t.integer :token_count
      t.integer :chunk_index
      t.jsonb :metadata, default: {}
      t.string :embedding_type, default: 'text'

      t.timestamps
    end

    add_index :ragdoll_embeddings, :document_id unless index_exists?(:ragdoll_embeddings, :document_id)
    add_index :ragdoll_embeddings, :chunk_index unless index_exists?(:ragdoll_embeddings, :chunk_index)
    add_index :ragdoll_embeddings, :embedding_type unless index_exists?(:ragdoll_embeddings, :embedding_type)
    add_index :ragdoll_embeddings, :metadata, using: :gin unless index_exists?(:ragdoll_embeddings, :metadata)
  end
end