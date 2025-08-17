# Increase multipart file limit for large directory uploads
# Default is 128, increase to 1000 to handle large directories
Rack::Utils.multipart_part_limit = 1000