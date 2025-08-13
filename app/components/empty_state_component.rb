# frozen_string_literal: true
class EmptyStateComponent < ApplicationComponent
  def initialize(title:, message:, icon:, action: nil, action_path: nil, action_text: nil, **options)
    @title = title
    @message = message
    @icon = icon
    @action = action
    @action_path = action_path
    @action_text = action_text
    @options = options
  end

  private

  attr_reader :title, :message, :icon, :action, :action_path, :action_text, :options

  def action_button
    return action if action
    return unless action_path && action_text

    link_to action_text, action_path, class: 'btn btn-primary'
  end
end
