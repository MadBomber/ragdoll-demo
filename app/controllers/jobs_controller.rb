class JobsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:restart_workers, :destroy]
  def index
    @pending_jobs = SolidQueue::Job.where(finished_at: nil).order(created_at: :desc).limit(50)
    @completed_jobs = SolidQueue::Job.where.not(finished_at: nil).order(finished_at: :desc).limit(50)
    @failed_jobs = SolidQueue::FailedExecution.order(created_at: :desc).limit(50)
    
    @stats = {
      pending: SolidQueue::Job.where(finished_at: nil).count,
      completed: SolidQueue::Job.where.not(finished_at: nil).count,
      failed: SolidQueue::FailedExecution.count,
      total: SolidQueue::Job.count
    }
  end
  
  def show
    @job = SolidQueue::Job.find(params[:id])
  end
  
  def retry
    failed_execution = SolidQueue::FailedExecution.find(params[:id])
    failed_execution.retry
    redirect_to jobs_path, notice: 'Job retried successfully'
  rescue => e
    redirect_to jobs_path, alert: "Failed to retry job: #{e.message}"
  end
  
  def destroy
    if params[:type] == 'failed'
      SolidQueue::FailedExecution.find(params[:id]).destroy
    else
      SolidQueue::Job.find(params[:id]).destroy
    end
    redirect_to jobs_path, notice: 'Job deleted successfully'
  rescue => e
    redirect_to jobs_path, alert: "Failed to delete job: #{e.message}"
  end
  
  def health
    health_status = WorkerHealthService.check_worker_health
    render json: health_status
  end
  
  def restart_workers
    if WorkerHealthService.needs_restart?
      # Process stuck jobs first
      processed_count = WorkerHealthService.process_stuck_jobs!(10)
      
      # Restart workers
      WorkerHealthService.restart_workers!
      
      redirect_to jobs_path, notice: "Workers restarted! Processed #{processed_count} stuck jobs."
    else
      redirect_to jobs_path, alert: "Workers appear to be healthy."
    end
  rescue => e
    redirect_to jobs_path, alert: "Failed to restart workers: #{e.message}"
  end
end