# frozen_string_literal: true
class CardComponent < ApplicationComponent
  def initialize(title: nil, icon: nil, header_actions: nil, **options)
    @title = title
    @icon = icon
    @header_actions = header_actions
    @options = options
  end

  private

  attr_reader :title, :icon, :header_actions, :options

  def card_classes
    classes = ['card']
    classes << options[:class] if options[:class]
    classes.join(' ')
  end


  def header_content
    return unless title || icon || header_actions

    content_tag :div, class: 'card-header d-flex justify-content-between align-items-center' do
      if title || icon
        concat(content_tag(:h5) do
          concat(content_tag(:i, '', class: icon)) if icon
          concat(" #{title}") if title
        end)
      end
      concat(header_actions) if header_actions
    end
  end
end
