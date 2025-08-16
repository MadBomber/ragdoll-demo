# ragdoll-demo/justfile

import "~/.justfile"

demo := justfile_directory()

# Default recipe
default: list

# Bundle install for ragdoll-demo
bundle:
    bundle install

# Start ragdoll-demo with all processes (foreman-based)
start: stop
    #!/bin/bash
    echo "🚀 Starting ragdoll-demo with all processes..."
    echo "🔄 Checking Redis server..."
    if ! pgrep -f "redis-server" > /dev/null; then
        echo "❌ Redis server is not running!"
        echo "💡 Please start Redis server first:"
        echo "   - Install: brew install redis"
        echo "   - Start:   brew services start redis"
        echo "   - Or run:  redis-server"
        exit 1
    else
        echo "✅ Redis server is running"
    fi
    echo "📦 Ensuring dependencies are up to date..."
    bundle install
    echo "🚀 Starting all processes..."
    ./bin/dev

# Stop ragdoll-demo and all its processes
stop:
    echo "🛑 Stopping ragdoll-demo and all processes..."
    ./bin/stop
    echo "ℹ️  Redis server is still running (managed separately)"
    echo "💡 To stop Redis: brew services stop redis"

# Emergency cleanup - kill all ragdoll processes forcefully
cleanup:
    echo "🧹 Emergency cleanup of all ragdoll processes..."
    -pkill -f "foreman.*Procfile.dev" || true
    -lsof -ti:3000 | xargs kill -9 2>/dev/null || true  
    -pkill -f "solid-queue" || true
    -pkill -f "jobs.*start" || true
    sleep 2
    echo "✅ All processes forcefully cleaned up"

# Restart ragdoll-demo (stop then start)
restart: stop start

# Show status of ragdoll-demo processes
status:
    #!/bin/bash
    echo "📊 Ragdoll Demo Process Status:"
    echo ""
    
    # Check Redis server
    if pgrep -f "redis-server" > /dev/null 2>&1; then
        echo "✅ Redis Server: Running"
        pgrep -f "redis-server" | head -1 | while read pid; do
            echo "   PID: $pid"
        done
    else
        echo "❌ Redis Server: Not running (required for ActionCable)"
    fi
    
    # Check for foreman processes
    if pgrep -f "foreman.*Procfile.dev" > /dev/null 2>&1; then
        echo "✅ Foreman: Running"
        pgrep -f "foreman.*Procfile.dev" | head -5 | while read pid; do
            echo "   PID: $pid"
        done
    else
        echo "❌ Foreman: Not running"
    fi
    
    # Check Rails server on port 3000
    if lsof -ti:3000 > /dev/null 2>&1; then
        echo "✅ Rails Server: Running on port 3000"
        lsof -ti:3000 | while read pid; do
            echo "   PID: $pid"
        done
    else
        echo "❌ Rails Server: Not running on port 3000"
    fi
    
    # Check SolidQueue workers
    if pgrep -f "jobs.*ragdoll-demo" > /dev/null 2>&1; then
        echo "✅ SolidQueue Workers: Running"
        pgrep -f "jobs.*ragdoll-demo" | head -5 | while read pid; do
            echo "   PID: $pid"
        done
    else
        echo "❌ SolidQueue Workers: Not running"
    fi
    
    echo ""
    echo "🌐 URLs:"
    echo "  - Application: http://localhost:3000"
    echo "  - Jobs Dashboard: http://localhost:3000/mission_control/jobs"

# Open ragdoll-demo in browser
open:
    echo "🌐 Opening ragdoll-demo in browser..."
    open http://localhost:3000

# Open job dashboard in browser
jobs:
    echo "💼 Opening job dashboard in browser..."
    open http://localhost:3000/mission_control/jobs

# View ragdoll-demo logs
logs:
    echo "📋 Viewing ragdoll-demo logs (press Ctrl+C to exit)..."
    tail -f log/development.log

# Run database migrations for ragdoll-demo
migrate:
    echo "🗄️ Running database migrations for ragdoll-demo..."
    rails db:migrate

# Reset ragdoll-demo database
db-reset:
    echo "🔄 Resetting ragdoll-demo database..."
    rails db:reset

# Setup ragdoll-demo database
db-setup:
    echo "🗄️ Setting up ragdoll-demo database..."
    rails db:setup

# Clean and update ragdoll-demo dependencies
bundle-clean:
    echo "💎 Cleaning and updating ragdoll-demo dependencies..."
    rm -f Gemfile.lock && bundle install

# Start Rails server
server:
    rails server

# Start Rails console
console:
    rails console