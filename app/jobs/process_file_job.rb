class ProcessFileJob < ApplicationJob
  queue_as :default

  def perform(file_id, session_id, filename, temp_path)
    puts "🚀 ProcessFileJob starting: file_id=#{file_id}, session_id=#{session_id}, filename=#{filename}"
    puts "📁 Temp file path: #{temp_path}"
    puts "📊 Temp file exists: #{File.exist?(temp_path)}"
    puts "📏 Temp file size: #{File.exist?(temp_path) ? File.size(temp_path) : 'N/A'} bytes"
    
    begin
      # Verify temp file exists before processing
      unless File.exist?(temp_path)
        raise "Temporary file not found: #{temp_path}"
      end
      
      # Broadcast start
      broadcast_data = {
        file_id: file_id,
        filename: filename,
        status: 'started',
        progress: 0,
        message: 'Starting file processing...'
      }
      
      puts "📡 Broadcasting start: #{broadcast_data}"
      begin
        ActionCable.server.broadcast("file_processing_#{session_id}", broadcast_data)
        puts "✅ ActionCable broadcast sent successfully"
      rescue => e
        puts "❌ ActionCable broadcast failed: #{e.message}"
        puts e.backtrace.first(3)
      end

      # Simulate progress updates during processing
      broadcast_progress(session_id, file_id, filename, 25, 'Reading file...')
      
      # Use Ragdoll to add document
      result = Ragdoll.add_document(path: temp_path)
      
      broadcast_progress(session_id, file_id, filename, 75, 'Generating embeddings...')
      
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
        begin
          ActionCable.server.broadcast("file_processing_#{session_id}", completion_data)
          puts "✅ Completion broadcast sent successfully"
        rescue => e
          puts "❌ Completion broadcast failed: #{e.message}"
        end
      else
        raise "Processing failed: #{result[:error] || 'Unknown error'}"
      end
      
    rescue => e
      puts "💥 ProcessFileJob error: #{e.message}"
      puts e.backtrace.first(5)
      
      # Broadcast error
      error_data = {
        file_id: file_id,
        filename: filename,
        status: 'error',
        progress: 0,
        message: "Error: #{e.message}"
      }
      
      puts "📡 Broadcasting error: #{error_data}"
      begin
        ActionCable.server.broadcast("file_processing_#{session_id}", error_data)
        puts "✅ Error broadcast sent successfully"
      rescue => e
        puts "❌ Error broadcast failed: #{e.message}"
      end
      
      # Re-raise the error to mark job as failed
      raise e
    ensure
      # ALWAYS clean up temp file in ensure block
      if temp_path && File.exist?(temp_path)
        puts "🧹 Cleaning up temp file: #{temp_path}"
        begin
          File.delete(temp_path)
          puts "✅ Temp file deleted successfully"
        rescue => e
          puts "❌ Failed to delete temp file: #{e.message}"
        end
      else
        puts "📝 Temp file already cleaned up or doesn't exist: #{temp_path}"
      end
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
    begin
      ActionCable.server.broadcast("file_processing_#{session_id}", broadcast_data)
      puts "✅ Progress broadcast sent successfully"
    rescue => e
      puts "❌ Progress broadcast failed: #{e.message}"
    end
    
    # Small delay to simulate processing time
    sleep(0.5)
  end
end