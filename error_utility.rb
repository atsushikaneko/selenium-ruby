class ErrorUtility
  def self.logger
    @logger ||= Logger.new('./logfile.log')
  end

  def self.log(e)
    p e.class
    p e.message
    p e.backtrace
    self.logger.error e.class
    self.logger.error e.message
    self.logger.error e.backtrace.join("\n")
  end
end