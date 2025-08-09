# Monkey patch to restore Logger#silence method for SolidQueue compatibility with Rails 8
# This can be removed when SolidQueue is updated to work with Rails 8

class Logger
  unless method_defined?(:silence)
    def silence(severity = Logger::ERROR)
      old_level = @level
      @level = severity
      yield
    ensure
      @level = old_level
    end
  end
end