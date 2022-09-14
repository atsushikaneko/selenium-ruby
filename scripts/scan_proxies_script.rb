require './crawler/amazon/scenario'
require './error_utility'

class ScanProxiesScript
  def execute
    scenaio = Crawler::Amazon::Scenario.new(
      start_url: "dummy",
      monitoring_target: "dummy",
      desired_arrival_amount: "dummy",
    )
    scenaio.scan_proxies
  end
end

ScanProxiesScript.new.execute if $PROGRAM_NAME == __FILE__