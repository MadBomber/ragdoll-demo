class DocumentsController < ApplicationController
  before_action :set_document, only: [:show, :edit, :update, :destroy, :preview, :reprocess, :download]
  skip_before_action :verify_authenticity_token, only: [:upload_async]
  
  def index
    @documents = Ragdoll::Document.all
    @documents = @documents.where(status: params[:status]) if params[:status].present?
    @documents = @documents.where(document_type: params[:document_type]) if params[:document_type].present?
    @documents = @documents.where('title ILIKE ?', "%#{params[:search]}%") if params[:search].present?
    @documents = @documents.order(created_at: :desc)
    
    @document_types = Ragdoll::Document.distinct.pluck(:document_type).compact
    @statuses = Ragdoll::Document.distinct.pluck(:status).compact
  end
  
  def show
    @embeddings = @document.all_embeddings
    # TODO: Implement search tracking
    # @recent_searches = Ragdoll::Search.order(created_at: :desc).limit(10)
    @recent_searches = []
  end
  
  def new
    @document = Ragdoll::Document.new
  end
  
  def create
    if params[:ragdoll_document] && params[:ragdoll_document][:files].present?
      uploaded_files = params[:ragdoll_document][:files]
      @results = []
      
      # Ensure uploaded_files is always an array
      uploaded_files = [uploaded_files] unless uploaded_files.is_a?(Array)
      
      uploaded_files.each do |file|
        begin
          # Skip if file is not a valid upload object
          next unless file.respond_to?(:original_filename)
          
          # Save uploaded file temporarily
          temp_path = Rails.root.join('tmp', 'uploads', file.original_filename)
          FileUtils.mkdir_p(File.dirname(temp_path))
          File.binwrite(temp_path, file.read)
          
          # Use Ragdoll to add document
          result = Ragdoll.add_document(path: temp_path.to_s)
          
          # Get the actual document object if successful
          if result[:success] && result[:document_id]
            document = Ragdoll::Document.find(result[:document_id])
            @results << { file: file.original_filename, success: true, document: document, message: result[:message] }
          else
            @results << { file: file.original_filename, success: false, error: result[:error] || "Unknown error" }
          end
          
          # Clean up temp file
          File.delete(temp_path) if File.exist?(temp_path)
        rescue => e
          filename = file.respond_to?(:original_filename) ? file.original_filename : file.to_s
          @results << { file: filename, success: false, error: e.message }
        end
      end
      
      render :upload_results
    elsif params[:ragdoll_document] && params[:ragdoll_document][:text_content].present?
      begin
        # For text content, we need to save it as a file first since Ragdoll.add_document expects a file
        temp_path = Rails.root.join('tmp', 'uploads', "#{SecureRandom.hex(8)}.txt")
        FileUtils.mkdir_p(File.dirname(temp_path))
        File.write(temp_path, params[:ragdoll_document][:text_content])
        
        @document = Ragdoll.add_document(path: temp_path.to_s)
        
        # Clean up temp file
        File.delete(temp_path) if File.exist?(temp_path)
        redirect_to document_path(@document), notice: 'Document was successfully created.'
      rescue => e
        @document = Ragdoll::Document.new
        @document.errors.add(:base, e.message)
        render :new
      end
    else
      @document = Ragdoll::Document.new
      @document.errors.add(:base, "Please provide either files or text content")
      render :new
    end
  end
  
  def edit
  end
  
  def update
    if @document.update(document_params)
      redirect_to document_path(@document), notice: 'Document was successfully updated.'
    else
      render :edit
    end
  end
  
  def destroy
    @document.destroy
    redirect_to documents_url, notice: 'Document was successfully deleted.'
  end
  
  def preview
    respond_to do |format|
      format.html { render layout: false }
      format.json { render json: { content: @document.content, metadata: @document.metadata } }
    end
  end
  
  def reprocess
    begin
      # Delete existing embeddings
      @document.all_embeddings.destroy_all
      
      # Reprocess document
      @document.update(status: 'pending')
      
      # Process embeddings in background
      Ragdoll::GenerateEmbeddingsJob.perform_later(@document.id)
      
      redirect_to document_path(@document), notice: 'Document reprocessing initiated.'
    rescue => e
      redirect_to document_path(@document), alert: "Error reprocessing document: #{e.message}"
    end
  end
  
  def download
    if @document.location.present? && File.exist?(@document.location)
      send_file @document.location, filename: @document.title
    else
      redirect_to document_path(@document), alert: 'File not found.'
    end
  end
  
  def bulk_upload
    if params[:directory_path].present?
      begin
        results = Ragdoll.add_directory(path: params[:directory_path])
        flash[:notice] = "Successfully processed #{results.count} files from directory."
      rescue => e
        flash[:alert] = "Error processing directory: #{e.message}"
      end
    end
    
    redirect_to documents_path
  end
  
  def bulk_delete
    if params[:document_ids].present?
      documents = Ragdoll::Document.where(id: params[:document_ids])
      count = documents.count
      documents.destroy_all
      flash[:notice] = "Successfully deleted #{count} documents."
    else
      flash[:alert] = "No documents selected for deletion."
    end
    
    redirect_to documents_path
  end
  
  def bulk_reprocess
    if params[:document_ids].present?
      documents = Ragdoll::Document.where(id: params[:document_ids])
      documents.each do |document|
        document.all_embeddings.destroy_all
        document.update(status: 'pending')
        Ragdoll::GenerateEmbeddingsJob.perform_later(document.id)
      end
      flash[:notice] = "Reprocessing initiated for #{documents.count} documents."
    else
      flash[:alert] = "No documents selected for reprocessing."
    end
    
    redirect_to documents_path
  end

  def upload_async
    Rails.logger.info "upload_async called with params: #{params.inspect}"
    Rails.logger.info "Session ID: #{session.id}"
    
    if params[:ragdoll_document] && params[:ragdoll_document][:files].present?
      session_id = session.id.to_s
      uploaded_files = params[:ragdoll_document][:files]
      
      Rails.logger.info "Files received: #{uploaded_files.inspect}"
      
      # Ensure uploaded_files is always an array
      uploaded_files = [uploaded_files] unless uploaded_files.is_a?(Array)
      
      processed_count = 0
      uploaded_files.each_with_index do |file, index|
        next unless file.respond_to?(:original_filename)
        
        Rails.logger.info "Processing file #{index + 1}: #{file.original_filename}"
        
        # Generate unique file ID
        file_id = "#{session_id}_#{index}_#{Time.current.to_i}"
        
        # Save uploaded file temporarily
        temp_path = Rails.root.join('tmp', 'uploads', "#{file_id}_#{file.original_filename}")
        FileUtils.mkdir_p(File.dirname(temp_path))
        File.binwrite(temp_path, file.read)
        
        Rails.logger.info "File saved to: #{temp_path}"
        
        # Queue background job
        ProcessFileJob.perform_later(file_id, session_id, file.original_filename, temp_path.to_s)
        Rails.logger.info "Job queued for file: #{file_id}"
        
        processed_count += 1
      end
      
      Rails.logger.info "Returning success response for #{processed_count} files"
      render json: { 
        success: true, 
        session_id: session_id,
        message: "#{processed_count} file(s) queued for processing" 
      }
    else
      Rails.logger.error "No files provided in upload_async"
      render json: { success: false, error: "No files provided" }, status: :bad_request
    end
  rescue => e
    Rails.logger.error "Error in upload_async: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { success: false, error: e.message }, status: :internal_server_error
  end
  
  def status
    @processing_stats = {
      pending: Ragdoll::Document.where(status: 'pending').count,
      processing: Ragdoll::Document.where(status: 'processing').count,
      processed: Ragdoll::Document.where(status: 'processed').count,
      failed: Ragdoll::Document.where(status: 'failed').count
    }
    
    @recent_activity = Ragdoll::Document.order(updated_at: :desc).limit(20)
    
    respond_to do |format|
      format.html
      format.json { render json: @processing_stats }
    end
  end
  
  private
  
  def set_document
    @document = Ragdoll::Document.find(params[:id])
  end
  
  def document_params
    params.require(:ragdoll_document).permit(:title, :content, :metadata, :status, :text_content, files: [])
  end
end