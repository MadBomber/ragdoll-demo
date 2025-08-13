# Development Scripts

This directory contains various debugging and utility scripts used during development.

## Job Management Scripts

### `fix_document_titles.rb`
- **Purpose**: Repair document titles in the database
- **Usage**: `rails runner scripts/fix_document_titles.rb`
- **Description**: Utility script for fixing document title data issues

### `process_all_jobs.rb` 
- **Purpose**: Process all pending jobs in the queue
- **Usage**: `rails runner scripts/process_all_jobs.rb`
- **Description**: Batch processes all queued SolidQueue jobs

### `process_jobs.rb`
- **Purpose**: Job processing utilities and helpers
- **Usage**: `rails runner scripts/process_jobs.rb`
- **Description**: Contains shared job processing functionality

### `process_one_job.rb`
- **Purpose**: Process a single job for testing/debugging
- **Usage**: `rails runner scripts/process_one_job.rb`
- **Description**: Useful for debugging individual job processing

## Testing Files

### `test_actioncable.js`
- **Purpose**: Test ActionCable functionality
- **Usage**: Include in browser console or test environment
- **Description**: JavaScript utilities for testing real-time features

### `test_document.md`
- **Purpose**: Sample document for testing uploads
- **Usage**: Use as test data for file upload functionality
- **Description**: Test content for document processing

### `test_progress.md`
- **Purpose**: Sample document for testing progress tracking
- **Usage**: Use as test data for real-time progress features
- **Description**: Test content for progress bar functionality

## Usage Notes

- All Ruby scripts should be run with `rails runner` to load the Rails environment
- Test files can be used as sample data for development and testing
- These scripts are for development/debugging purposes only
- Do not run in production without careful consideration