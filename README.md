# Ragdoll Demo

A demonstration Rails application showcasing the Ragdoll document processing and search engine.

## Quick Start

The easiest way to run the application with all processes:

```bash
./bin/dev
```

This will:
- **Cleanup** any existing processes automatically
- **Update gems** automatically if Gemfile has changed or gems are missing
- Check and setup the database if needed
- Run pending migrations
- Start the Rails server on port 3000
- Start the background job worker

**Stop the application:**
```bash
./bin/stop
```

**Check status:**
```bash
./bin/status
```

## Manual Process Management

### Development (Foreman)

Start all processes with foreman:
```bash
bundle exec foreman start -f Procfile.dev
```

Or start specific processes:
```bash
# Web server only
bundle exec foreman start web -f Procfile.dev

# Background worker only  
bundle exec foreman start worker -f Procfile.dev
```

### Individual Processes

Start processes individually:
```bash
# Rails server
bundle exec rails server -p 3000

# Background jobs (SolidQueue)
bundle exec jobs
```

## Process Configuration

### Files

- **`Procfile`** - Production process definitions
- **`Procfile.dev`** - Development process definitions  
- **`.foreman`** - Foreman configuration (port, timeout, formation)
- **`.env.example`** - Environment variables template

### Available Processes

- **web**: Rails application server (Puma)
- **worker**: Background job processor (SolidQueue)

## Environment Setup

1. Copy environment variables:
```bash
cp .env.example .env
```

2. Edit `.env` with your configuration

3. Install dependencies:
```bash
bundle install
```

4. Setup database:
```bash
bundle exec rails db:setup
```

## Requirements

- Ruby 3.4.4+
- Rails 8.0.2+
- PostgreSQL with pgvector extension
- Redis (for ActionCable and real-time features)
- Node.js (for asset compilation)

### Installing Redis

**macOS (using Homebrew):**
```bash
# Install Redis
brew install redis

# Start Redis service
brew services start redis

# Or run Redis manually
redis-server
```

**Ubuntu/Debian:**
```bash
# Install Redis
sudo apt update
sudo apt install redis-server

# Start Redis service
sudo systemctl start redis-server
sudo systemctl enable redis-server
```

**Verify Redis is running:**
```bash
redis-cli ping
# Should return: PONG
```

## Architecture

- **Frontend**: Rails views with ViewComponent, Turbo, Stimulus
- **Background Jobs**: SolidQueue with PostgreSQL adapter
- **Database**: PostgreSQL with vector extensions (pgvector)
- **Search**: Elasticsearch/OpenSearch integration via Ragdoll engine
- **Process Management**: Foreman for development, systemd/Docker for production

## Development

The application uses:
- **ViewComponent** for reusable UI components
- **Hotwire (Turbo + Stimulus)** for interactive features
- **SolidQueue** for reliable background job processing
- **Ragdoll Engine** for document processing and vector search

## Just (Task Runner) Integration

From the parent `meta` directory, you can use Just recipes:

```bash
# Start the demo
just start  # or just demo-start

# Stop the demo  
just stop   # or just demo-stop

# Restart the demo
just restart  # or just demo-restart

# Check status
just status  # or just demo-status

# View logs
just logs  # or just demo-logs

# Open in browser
just demo-open

# Open job dashboard
just demo-jobs

# Database operations
just demo-migrate
just demo-db-setup
just demo-db-reset

# Gem management
just demo-bundle       # Update gems
just demo-bundle-clean # Clean and update gems
```

## Monitoring

- **Process Status**: `./bin/status` or `just status`
- **Background Jobs**: Visit `/mission_control/jobs` or `just demo-jobs`
- **Application Logs**: `tail -f log/development.log` or `just logs`
- **Real-time Status**: All processes are monitored and can be managed independently

## Process Management Features

### Automatic Cleanup
- **Smart Startup**: `./bin/dev` automatically kills any existing processes before starting
- **Gem Management**: Automatically runs `bundle install` when Gemfile changes or gems are missing
- **Port Conflict Resolution**: Automatically frees port 3000 if occupied
- **Graceful Shutdown**: Proper signal handling for clean shutdowns

### Process Monitoring
- **Real-time Status**: Check running processes with `./bin/status`
- **Process Discovery**: Automatically detects Rails servers, workers, and foreman processes
- **PID Tracking**: Shows process IDs for debugging and manual management

## Troubleshooting

### Redis Connection Issues

If you see errors related to Redis or ActionCable:

1. **Check if Redis is running:**
   ```bash
   redis-cli ping
   ```

2. **Start Redis if not running:**
   ```bash
   # macOS
   brew services start redis
   
   # Ubuntu/Debian
   sudo systemctl start redis-server
   ```

3. **Check Redis logs:**
   ```bash
   # macOS
   tail -f /opt/homebrew/var/log/redis.log
   
   # Ubuntu/Debian
   sudo tail -f /var/log/redis/redis-server.log
   ```

### Application Won't Start

1. **Check all requirements are installed:**
   - Ruby 3.4.4+: `ruby --version`
   - Rails 8.0.2+: `rails --version`
   - PostgreSQL: `psql --version`
   - Redis: `redis-cli ping`
   - Node.js: `node --version`

2. **Run the comprehensive startup script:**
   ```bash
   # From the meta directory
   just start
   ```
   This script checks for Redis and provides helpful error messages.

3. **Manual cleanup if needed:**
   ```bash
   ./bin/stop
   # Or from meta directory
   just cleanup
   ```

### Database Issues

If you encounter database problems:

1. **Ensure PostgreSQL is running:**
   ```bash
   # macOS
   brew services start postgresql
   
   # Ubuntu/Debian
   sudo systemctl start postgresql
   ```

2. **Create database if missing:**
   ```bash
   bundle exec rails db:setup
   ```

3. **Install pgvector extension:**
   ```sql
   # Connect to your database and run:
   CREATE EXTENSION IF NOT EXISTS vector;
   ```
