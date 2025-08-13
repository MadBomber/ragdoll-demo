# frozen_string_literal: true
class PageHeaderComponent < ApplicationComponent
  def initialize(title:, icon: nil, subtitle: nil)
    @title = title
    @icon = icon
    @subtitle = subtitle
  end


  def call
    content_tag :div, class: 'row' do
      content_tag :div, class: 'col-12' do
        content_tag :div, class: 'mb-4' do
          concat(content_tag(:h1) do
            concat(content_tag(:i, '', class: icon)) if icon
            concat(" #{title}")
          end)
          concat(content_tag(:p, subtitle, class: 'text-muted')) if subtitle
        end
      end
    end
  end

  private

  attr_reader :title, :icon, :subtitle
end
