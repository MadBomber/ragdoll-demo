# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 6) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "unaccent"
  enable_extension "uuid-ossp"
  enable_extension "vector"

  create_table "ragdoll_contents", comment: "Content storage for polymorphic embedding architecture using STI", force: :cascade do |t|
    t.string "type", null: false, comment: "Type of content (e.g., AudioContent, ImageContent, TextContent)"
    t.bigint "document_id", null: false, comment: "Reference to parent document"
    t.string "embedding_model", null: false, comment: "Embedding model to use for this content"
    t.text "content", comment: "Text content or description of the file"
    t.text "data", comment: "Raw data from file"
    t.json "metadata", default: {}, comment: "Additional metadata about the file's raw data"
    t.float "duration", comment: "Duration of audio in seconds (for audio content)"
    t.integer "sample_rate", comment: "Audio sample rate in Hz (for audio content)"
    t.datetime "created_at", null: false, comment: "Standard creation and update timestamps"
    t.datetime "updated_at", null: false, comment: "Standard creation and update timestamps"
    t.index "to_tsvector('english'::regconfig, COALESCE(content, ''::text))", name: "index_ragdoll_contents_on_fulltext_search", using: :gin, comment: "Full-text search index for text content"
    t.index ["document_id"], name: "index_ragdoll_contents_on_document_id"
    t.index ["embedding_model"], name: "index_ragdoll_contents_on_embedding_model", comment: "Index for filtering by embedding model"
    t.index ["type"], name: "index_ragdoll_contents_on_type", comment: "Index for filtering by content type"
  end

  create_table "ragdoll_documents", comment: "Core documents table with LLM-generated structured metadata", force: :cascade do |t|
    t.string "location", null: false, comment: "Source location of document (file path, URL, or identifier)"
    t.string "title", null: false, comment: "Human-readable document title for display and search"
    t.text "summary", default: "", null: false, comment: "LLM-generated summary of document content"
    t.text "keywords", default: "", null: false, comment: "LLM-generated comma-separated keywords of document"
    t.string "document_type", default: "text", null: false, comment: "Document format type"
    t.string "status", default: "pending", null: false, comment: "Document processing status"
    t.json "metadata", default: {}, comment: "LLM-generated structured metadata about the file"
    t.datetime "file_modified_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false, comment: "Timestamp when the source file was last modified"
    t.datetime "created_at", null: false, comment: "Standard creation and update timestamps"
    t.datetime "updated_at", null: false, comment: "Standard creation and update timestamps"
    t.index "((metadata ->> 'classification'::text))", name: "index_ragdoll_documents_on_metadata_classification", comment: "Index for filtering by document classification"
    t.index "((metadata ->> 'document_type'::text))", name: "index_ragdoll_documents_on_metadata_type", comment: "Index for filtering by document type"
    t.index "to_tsvector('english'::regconfig, (((((((COALESCE(title, ''::character varying))::text || ' '::text) || COALESCE((metadata ->> 'summary'::text), ''::text)) || ' '::text) || COALESCE((metadata ->> 'keywords'::text), ''::text)) || ' '::text) || COALESCE((metadata ->> 'description'::text), ''::text)))", name: "index_ragdoll_documents_on_fulltext_search", using: :gin, comment: "Full-text search across title and metadata fields"
    t.index ["created_at"], name: "index_ragdoll_documents_on_created_at", comment: "Index for chronological sorting"
    t.index ["document_type", "status"], name: "index_ragdoll_documents_on_document_type_and_status", comment: "Composite index for type+status filtering"
    t.index ["document_type"], name: "index_ragdoll_documents_on_document_type", comment: "Index for filtering by document type"
    t.index ["location"], name: "index_ragdoll_documents_on_location", unique: true, comment: "Unique index for document source lookup"
    t.index ["status"], name: "index_ragdoll_documents_on_status", comment: "Index for filtering by processing status"
    t.index ["title"], name: "index_ragdoll_documents_on_title", comment: "Index for title-based search"
  end

  create_table "ragdoll_embeddings", comment: "Polymorphic vector embeddings storage for semantic similarity search", force: :cascade do |t|
    t.string "embeddable_type", null: false
    t.bigint "embeddable_id", null: false, comment: "Polymorphic reference to embeddable content"
    t.text "content", default: "", null: false, comment: "Original text content that was embedded"
    t.vector "embedding_vector", limit: 1536, null: false, comment: "Vector embedding using pgvector"
    t.integer "chunk_index", null: false, comment: "Chunk index for ordering embeddings"
    t.integer "usage_count", default: 0, comment: "Number of times used in similarity searches"
    t.datetime "returned_at", comment: "Timestamp of most recent usage"
    t.json "metadata", default: {}, comment: "Embedding-specific metadata (positions, processing info)"
    t.datetime "created_at", null: false, comment: "Standard creation and update timestamps"
    t.datetime "updated_at", null: false, comment: "Standard creation and update timestamps"
    t.index ["embeddable_type", "embeddable_id"], name: "index_ragdoll_embeddings_on_embeddable"
    t.index ["embeddable_type", "embeddable_id"], name: "index_ragdoll_embeddings_on_embeddable_type_and_embeddable_id", comment: "Index for finding embeddings by embeddable content"
    t.index ["embedding_vector"], name: "index_ragdoll_embeddings_on_embedding_vector_cosine", opclass: :vector_cosine_ops, using: :ivfflat, comment: "IVFFlat index for fast cosine similarity search"
  end

  add_foreign_key "ragdoll_contents", "ragdoll_documents", column: "document_id"
end
