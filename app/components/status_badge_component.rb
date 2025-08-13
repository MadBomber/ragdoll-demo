# frozen_string_literal: true
class StatusBadgeComponent < ApplicationComponent
  def initialize(status:, **options)
    @status = status
    @options = options
  end

  private

  attr_reader :status, :options

  def badge_classes
    base_classes = ['badge']
    base_classes << "bg-#{badge_color}"
    base_classes << options[:class] if options[:class]
    base_classes.join(' ')
  end


  def badge_color
    case status.to_s
    when 'processed', 'success'
      'success'
    when 'failed', 'error'
      'danger'
    when 'processing', 'pending'
      'warning'
    else
      'secondary'
    end
  end


  def display_text
    status.to_s.titleize
  end
end
