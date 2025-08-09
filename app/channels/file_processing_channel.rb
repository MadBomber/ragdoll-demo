class FileProcessingChannel < ApplicationCable::Channel
  def subscribed
    stream_from "file_processing_#{params[:session_id]}"
  end

  def unsubscribed
  end
end