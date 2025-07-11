# This migration comes from ragdoll (originally 20250223123457)
class AddMetadataAndForeignKeyToRagdollTables < ActiveRecord::Migration[8.0]
  def change
    create_table :ragdoll_searches do |t|
      t.text :query, null: false
      # Use text instead of vector for compatibility
      t.text :query_embedding
      t.string :search_type, default: 'semantic'
      t.jsonb :filters, default: {}
      t.jsonb :results, default: {}
      t.integer :result_count, default: 0
      t.float :search_time
      t.string :model_name

      t.timestamps
    end

    add_index :ragdoll_searches, :search_type unless index_exists?(:ragdoll_searches, :search_type)
    add_index :ragdoll_searches, :created_at unless index_exists?(:ragdoll_searches, :created_at)
  end
end
