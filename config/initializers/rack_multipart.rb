# frozen_string_literal: true

# Increase multipart file limit for large directory uploads
# Default is 128, increase to 2000 to handle very large directories (1256+ files)
Rack::Utils.multipart_part_limit = 2000

# Also set the file limit
Rack::Utils.multipart_file_limit = 2000