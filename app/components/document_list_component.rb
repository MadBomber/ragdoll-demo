# frozen_string_literal: true
class DocumentListComponent < ApplicationComponent
  def initialize(documents:)
    @documents = documents
  end

  private

  attr_reader :documents

  def document_actions(document)
    actions = []

    actions << {
      path: document_path(document),
      title: 'View document details',
      icon: 'fas fa-eye',
      class: 'btn btn-outline-primary btn-sm'
    }

    actions << {
      path: preview_document_path(document),
      title: 'Preview document content',
      icon: 'fas fa-search',
      class: 'btn btn-outline-info btn-sm',
      target: '_blank'
    }

    if document.status == 'failed'
      actions << {
        onclick: "reprocessDocument(#{document.id})",
        title: 'Retry failed document',
        icon: 'fas fa-redo',
        text: 'Retry',
        class: 'btn btn-danger btn-sm'
      }
    elsif document.status == 'processed'
      actions << {
        onclick: "reprocessDocument(#{document.id})",
        title: 'Reprocess document embeddings',
        icon: 'fas fa-sync',
        class: 'btn btn-outline-warning btn-sm'
      }
    end

    actions << {
      path: edit_document_path(document),
      title: 'Edit document details',
      icon: 'fas fa-edit',
      class: 'btn btn-outline-secondary btn-sm'
    }

    actions << {
      path: document_path(document),
      method: :delete,
      title: 'Delete document permanently',
      icon: 'fas fa-trash',
      class: 'btn btn-outline-danger btn-sm',
      confirm: 'Are you sure you want to delete this document?'
    }

    actions
  end


  def character_count_display(document)
    if document.total_character_count.positive?
      pluralize(document.total_character_count, 'character')
    else
      content_tag(:span, '-', class: 'text-muted')
    end
  end
end
