class FileProcessingChannel < ApplicationCable::Channel
  def subscribed
    stream_from "file_processing_#{params[:session_id]}"
    puts "📡 FileProcessingChannel subscribed to file_processing_#{params[:session_id]}"
  end

  def unsubscribed
    puts "📡 FileProcessingChannel unsubscribed from file_processing_#{params[:session_id]}"
  end

  def test_connection
    puts "🏓 Received test_connection ping from session: #{params[:session_id]}"
    ActionCable.server.broadcast("file_processing_#{params[:session_id]}", {
      type: "ping",
      message: "Connection test successful",
      timestamp: Time.current.to_f
    })
  end
end
