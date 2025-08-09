class ProcessFileJob < ApplicationJob
  queue_as :default

  def perform(file_id, session_id, filename, temp_path)
    puts "🚀 ProcessFileJob starting: file_id=#{file_id}, session_id=#{session_id}, filename=#{filename}"
    
    begin
      # Broadcast start
      broadcast_data = {
        file_id: file_id,
        filename: filename,
        status: 'started',
        progress: 0,
        message: 'Starting file processing...'
      }
      
      puts "📡 Broadcasting start: #{broadcast_data}"
      ActionCable.server.broadcast("file_processing_#{session_id}", broadcast_data)

      # Simulate progress updates during processing
      broadcast_progress(session_id, file_id, filename, 25, 'Reading file...')
      
      # Use Ragdoll to add document
      result = Ragdoll.add_document(path: temp_path)
      
      broadcast_progress(session_id, file_id, filename, 75, 'Generating embeddings...')
      
      # Clean up temp file
      File.delete(temp_path) if File.exist?(temp_path)
      
      if result[:success] && result[:document_id]
        document = Ragdoll::Document.find(result[:document_id])
        
        # Broadcast completion
        completion_data = {
          file_id: file_id,
          filename: filename,
          status: 'completed',
          progress: 100,
          message: 'Processing completed successfully',
          document_id: document.id,
          document_url: Rails.application.routes.url_helpers.document_path(document)
        }
        
        puts "🎉 Broadcasting completion: #{completion_data}"
        ActionCable.server.broadcast("file_processing_#{session_id}", completion_data)
      else
        raise "Processing failed: #{result[:error] || 'Unknown error'}"
      end
      
    rescue => e
      puts "💥 ProcessFileJob error: #{e.message}"
      puts e.backtrace.first(3)
      
      # Clean up temp file on error
      File.delete(temp_path) if File.exist?(temp_path)
      
      # Broadcast error
      error_data = {
        file_id: file_id,
        filename: filename,
        status: 'error',
        progress: 0,
        message: "Error: #{e.message}"
      }
      
      puts "📡 Broadcasting error: #{error_data}"
      ActionCable.server.broadcast("file_processing_#{session_id}", error_data)
    end
  end

  private

  def broadcast_progress(session_id, file_id, filename, progress, message)
    broadcast_data = {
      file_id: file_id,
      filename: filename,
      status: 'processing',
      progress: progress,
      message: message
    }
    
    puts "📡 Broadcasting progress: #{broadcast_data}"
    ActionCable.server.broadcast("file_processing_#{session_id}", broadcast_data)
    
    # Small delay to simulate processing time
    sleep(0.5)
  end
end