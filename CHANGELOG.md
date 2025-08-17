# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.11] - 2025-08-17

### Added
- Detailed logging for Ragdoll operations and performance metrics
- StuckJobMonitorJob for monitoring and cleaning up stuck background jobs
- JobFailureMonitorService for tracking job failures
- Justfile for ragdoll-demo setup and management tasks
- Home controller and landing page view for Ragdoll Demo
- Initialized ragdoll-rails genetic codebase
- Example environment configuration and Foreman setup
- Temporary file cleanup system
- Manual worker monitoring script
- Job concurrency settings for enhanced file upload processing
- Redis gem integration for improved channel communication
- Procfile and development scripts for job management
- Enhanced logging in FileProcessingChannel

### Changed
- Updated ragdoll-rails to use local path for development
- Enhanced logging for search parameters and errors
- Improved file upload processing with better concurrency control
- Removed reliable upload section from documents new view

### Fixed
- Upgraded rmagick to version 6.1.3 in Gemfile.lock
- Updated Rails dependencies to version 8.0.2.1 for all Action* and Active* components

### Security
- Implemented proper file cleanup to prevent disk space issues

## [0.1.10] - Previous Release
- Base version established with core functionality
