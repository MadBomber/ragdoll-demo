# frozen_string_literal: true
class NavbarComponent < ApplicationComponent
  def initialize(brand_text: 'Ragdoll Engine Demo', brand_path: '/')
    @brand_text = brand_text
    @brand_path = brand_path
  end

  private

  attr_reader :brand_text, :brand_path

  def nav_items
    [
      { text: 'Dashboard', path: dashboard_path, icon: 'fas fa-tachometer-alt' },
      { text: 'Documents', path: documents_path, icon: 'fas fa-file-alt' },
      { text: 'Search', path: search_path, icon: 'fas fa-search' },
      { text: 'Jobs', path: '/jobs', icon: 'fas fa-tasks' },
      { text: 'Analytics', path: analytics_path, icon: 'fas fa-chart-line' },
      { text: 'Configuration', path: configuration_path, icon: 'fas fa-cog' }
    ]
  end


  def nav_link_classes(path)
    base_classes = ['nav-link']
    base_classes << 'active' if current_page?(path)
    base_classes.join(' ')
  end
end
