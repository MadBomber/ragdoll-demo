# Temporary File Cleanup System

This document describes the automatic cleanup system for temporary upload files in the ragdoll-demo application.

## Overview

The application saves uploaded files to `tmp/uploads/` during processing. To prevent disk space issues, several cleanup mechanisms are in place:

## Automatic Cleanup (Built-in)

### 1. **Job-Level Cleanup**
- **Location**: `app/jobs/process_file_job.rb`
- **Mechanism**: Uses `ensure` block to guarantee cleanup
- **Timing**: Immediately after successful processing or on any error
- **Coverage**: All files processed through background jobs

### 2. **Controller-Level Cleanup** 
- **Location**: `app/controllers/documents_controller.rb`
- **Methods**: `create`, `bulk_upload` methods
- **Coverage**: Synchronous uploads and bulk directory uploads

## Manual Cleanup Tools

### 3. **Rake Tasks**
```bash
# Clean files older than 1 hour
bin/rails cleanup:temp_files

# Force clean all temp files (emergency cleanup)
bin/rails cleanup:force_temp_files
```

### 4. **Standalone Script**
```bash
# Clean files older than 2 hours
bin/cleanup_temp_files
```

## Scheduled Cleanup (Recommended)

### Cron Job Setup
Add to your crontab to run cleanup every 6 hours:

```bash
# Edit crontab
crontab -e

# Add this line (adjust path as needed)
0 */6 * * * /path/to/ragdoll-demo/bin/cleanup_temp_files >> /path/to/logs/cleanup.log 2>&1
```

### Alternative: Systemd Timer
For systemd-based systems, create a timer:

```ini
# /etc/systemd/system/ragdoll-cleanup.service
[Unit]
Description=Ragdoll Demo Temp File Cleanup
After=network.target

[Service]
Type=oneshot
User=rails
WorkingDirectory=/path/to/ragdoll-demo
ExecStart=/path/to/ragdoll-demo/bin/cleanup_temp_files

# /etc/systemd/system/ragdoll-cleanup.timer
[Unit]
Description=Run Ragdoll cleanup every 6 hours
Requires=ragdoll-cleanup.service

[Timer]
OnCalendar=*-*-* 00,06,12,18:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

Enable with:
```bash
sudo systemctl enable ragdoll-cleanup.timer
sudo systemctl start ragdoll-cleanup.timer
```

## Monitoring

### Check Current Status
```bash
# List current temp files
ls -la tmp/uploads/

# Check disk usage
du -sh tmp/uploads/

# View cleanup logs (if using cron)
tail -f /path/to/logs/cleanup.log
```

### Manual Inspection
```bash
# Find files older than 1 hour
find tmp/uploads -type f -mmin +60 -not -path "*/cache/*"

# Count temp files
find tmp/uploads -type f -not -path "*/cache/*" | wc -l
```

## Troubleshooting

### Problem: Files Not Being Cleaned Up
1. **Check job logs**: Look for errors in `ProcessFileJob`
2. **Verify ensure block**: Confirm `ProcessFileJob.perform` completes
3. **Run manual cleanup**: Use `bin/rails cleanup:temp_files`
4. **Check permissions**: Ensure Rails can delete files in `tmp/uploads/`

### Problem: Disk Space Issues
1. **Emergency cleanup**: `bin/rails cleanup:force_temp_files`
2. **Check for large files**: `find tmp/uploads -type f -size +100M`
3. **Verify cron is running**: `crontab -l` and check logs

### Problem: Performance Issues
- **Large directories**: Consider increasing cleanup frequency
- **Many small files**: Check if jobs are failing and leaving orphans
- **Network storage**: Ensure cleanup works with mounted filesystems

## Configuration

### Cleanup Timing
- **Job cleanup**: Immediate (on job completion/failure)
- **Rake task**: Files older than 1 hour  
- **Standalone script**: Files older than 2 hours (conservative)

### Exclusions
- Files in `tmp/uploads/cache/` are preserved
- Only files in `tmp/uploads/` are cleaned (not subdirectories unless specified)

## Best Practices

1. **Monitor regularly**: Set up alerts for disk usage
2. **Schedule cleanup**: Use cron or systemd timers
3. **Test cleanup**: Periodically verify cleanup is working
4. **Log cleanup**: Keep logs of cleanup operations
5. **Backup strategy**: Ensure cleanup doesn't interfere with backups

## Security Notes

- Cleanup scripts only operate on `tmp/uploads/`
- Files are permanently deleted (not moved to trash)
- Scripts verify file age before deletion
- No sensitive data should be in temp files anyway