# This migration comes from ragdoll (originally 20250225123456)
class AddSummaryToRagdollDocuments < ActiveRecord::Migration[8.0]
  def change
    # Summary field already exists, just add metadata fields
    add_column :ragdoll_documents, :summary_generated_at, :timestamp unless column_exists?(:ragdoll_documents, :summary_generated_at)
    add_column :ragdoll_documents, :summary_model, :string unless column_exists?(:ragdoll_documents, :summary_model)
    
    # Add index for searching by summary metadata
    add_index :ragdoll_documents, :summary_generated_at unless index_exists?(:ragdoll_documents, :summary_generated_at)
    add_index :ragdoll_documents, :summary_model unless index_exists?(:ragdoll_documents, :summary_model)
  end
end