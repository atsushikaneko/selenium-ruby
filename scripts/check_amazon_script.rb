require './dynamo_db'
require 'parallel'
require './twitter_api'
require './crawler/amazon/scenario'
require './error_utility'

class CheckAmazonScript
  def execute
    dynamo_db = DynamoDb.new('amazon_item_list')
    rows = dynamo_db.all
    # rowsを絞る
    puts rows = rows[0..2]
    # puts rows = [rows[0]]
  
    whole_start_time = Time.now # 全体時間測定

    target_rows = []
    Parallel.each(rows, in_threads: 5) do |row|
      start_time = Time.now # 時間測定
  
      scenaio = Crawler::Amazon::Scenario.new(
        start_url: row["start_url"],
        desired_arrival_amount: row["desired_arrival_amount"].to_i,
        post_content: row["post_contents"]
      )
      target_rows << row if scenaio.item_in_stock_by_target_sellers?
  
      p "個別処理概要 #{Time.now - start_time}s" # 個別時間測定
    end
  
    if target_rows.any?
    twitter_api  = TwitterApi.new
  
      target_rows.each do |row|
        if tweetable?(row)
          puts "ツイートします"
          # puts row["post_contents"]
          # twitter_api.tweet(row["post_contents"])
          dynamo_db.update(id: row["id"], column: "last_tweeted_at", value: Time.now.to_s)
          sleep(rand(20..30))
        end
      end
  
      p "全体処理概要 #{Time.now - whole_start_time}s" # 時間測定
    end
  
  rescue => e
    ErrorUtility.log(e)
  end

  private

  # TWEET_INTERVAL = 1800.freeze # 1800秒
  TWEET_INTERVAL = 0.freeze # 0秒
  def tweetable?(row)
    return true if row["last_tweeted_at"] == nil # last_tweeted_atがnilの場合はツイート可能

    last_tweeted_at = Time.parse(row["last_tweeted_at"])
    Time.now > last_tweeted_at + TWEET_INTERVAL
  end

  def logger
    @logger ||= Logger.new('./logfile.log')
  end
end

CheckAmazonScript.new.execute if $PROGRAM_NAME == __FILE__