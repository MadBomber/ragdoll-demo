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

ActiveRecord::Schema[8.0].define(version: 2025_08_09_044137) do
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

  create_table "ragdoll_search_results", comment: "Junction table linking searches to their returned embeddings", force: :cascade do |t|
    t.bigint "search_id", null: false, comment: "Reference to the search query"
    t.bigint "embedding_id", null: false, comment: "Reference to the returned embedding"
    t.float "similarity_score", null: false, comment: "Similarity score for this result"
    t.integer "result_rank", null: false, comment: "Ranking position of this result (1-based)"
    t.boolean "clicked", default: false, comment: "Whether user interacted with this result"
    t.datetime "clicked_at", comment: "Timestamp when result was clicked/selected"
    t.datetime "created_at", null: false, comment: "Standard creation and update timestamps"
    t.datetime "updated_at", null: false, comment: "Standard creation and update timestamps"
    t.index ["clicked", "clicked_at"], name: "idx_search_results_clicks", comment: "Index for click-through analysis"
    t.index ["embedding_id", "similarity_score"], name: "idx_search_results_embedding_score", comment: "Index for analyzing embedding performance"
    t.index ["embedding_id"], name: "index_ragdoll_search_results_on_embedding_id"
    t.index ["search_id", "result_rank"], name: "idx_search_results_search_rank", comment: "Index for retrieving results in ranked order"
    t.index ["search_id"], name: "index_ragdoll_search_results_on_search_id"
    t.index ["similarity_score"], name: "idx_search_results_similarity", comment: "Index for similarity score analysis"
  end

  create_table "ragdoll_searches", comment: "Search queries and results tracking with vector similarity support", force: :cascade do |t|
    t.text "query", null: false, comment: "Original search query text"
    t.vector "query_embedding", limit: 1536, null: false, comment: "Vector embedding of the search query for similarity matching"
    t.string "search_type", default: "semantic", null: false, comment: "Type of search performed (semantic, hybrid, fulltext)"
    t.integer "results_count", default: 0, null: false, comment: "Number of results returned for this search"
    t.float "max_similarity_score", comment: "Highest similarity score from results"
    t.float "min_similarity_score", comment: "Lowest similarity score from results"
    t.float "avg_similarity_score", comment: "Average similarity score of results"
    t.json "search_filters", default: {}, comment: "Filters applied during search (document_type, date_range, etc.)"
    t.json "search_options", default: {}, comment: "Search configuration options (threshold, limit, etc.)"
    t.integer "execution_time_ms", comment: "Search execution time in milliseconds"
    t.string "session_id", comment: "User session identifier for grouping related searches"
    t.string "user_id", comment: "User identifier if authentication is available"
    t.datetime "created_at", null: false, comment: "Standard creation and update timestamps"
    t.datetime "updated_at", null: false, comment: "Standard creation and update timestamps"
    t.index "to_tsvector('english'::regconfig, query)", name: "index_ragdoll_searches_on_fulltext_query", using: :gin, comment: "Full-text search index for finding searches by query text"
    t.index ["created_at"], name: "index_ragdoll_searches_on_created_at", comment: "Index for chronological search history"
    t.index ["query_embedding"], name: "index_ragdoll_searches_on_query_embedding_cosine", opclass: :vector_cosine_ops, using: :ivfflat, comment: "IVFFlat index for finding similar search queries"
    t.index ["results_count"], name: "index_ragdoll_searches_on_results_count", comment: "Index for analyzing search effectiveness"
    t.index ["search_type"], name: "index_ragdoll_searches_on_search_type", comment: "Index for filtering by search type"
    t.index ["session_id"], name: "index_ragdoll_searches_on_session_id", comment: "Index for grouping searches by session"
    t.index ["user_id"], name: "index_ragdoll_searches_on_user_id", comment: "Index for filtering searches by user"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  add_foreign_key "ragdoll_contents", "ragdoll_documents", column: "document_id"
  add_foreign_key "ragdoll_search_results", "ragdoll_embeddings", column: "embedding_id"
  add_foreign_key "ragdoll_search_results", "ragdoll_searches", column: "search_id"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
