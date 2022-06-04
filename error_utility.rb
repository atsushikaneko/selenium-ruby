class ErrorUtility
  def self.logger
    @logger = Logger.new('./logfile.log')
  end

  def self.log(e)
    puts e.class
    puts e.message
    puts e.backtrace
    self.logger.error e.class
    self.logger.error e.message
    self.logger.error e.backtrace.join("\n")
  end
end