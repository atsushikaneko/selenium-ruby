require './dynamo_db'
require 'parallel'
require './twitter_api'
require './crawler/amazon/scenario'
require './error_utility'

class CheckAmazonScript
  TABLE_NAME = 'amazon_item_list'.freeze
  # TWEET_INTERVAL = 1800.freeze # 1800秒
  TWEET_INTERVAL = 0.freeze # 0秒
  DEFAULT_TWEET_INTERVAL = 1800.freeze # 0秒

  def execute
    overall_start_time = Time.now # 全体時間測定

    rows = dynamo_db.all
    # rowsを絞る
    p rows = rows[0..2]
    # p rows = [rows[0]]

    target_rows = []
    Parallel.each(rows, in_threads: 5) do |row|
      start_time = Time.now # 個別時間測定
  
      scenaio = Crawler::Amazon::Scenario.new(
        start_url: row["start_url"],
        desired_arrival_amount: row["desired_arrival_amount"].to_i,
        post_content: row["post_contents"]
      )
      target_rows << row if scenaio.item_in_stock_by_target_sellers?
  
      p "個別処理概要 #{Time.now - start_time}s" # 個別時間測定
    end
  
    target_rows.each do |row|
      if tweetable?(row)
        p "ツイートします"
        # p row["post_contents"]
        # twitter_api.tweet(row["post_contents"])
        dynamo_db.update(id: row["id"], column: "last_tweeted_at", value: Time.now.to_s)
        # sleep(rand(20..30))
      end
    end
  
    p "全体処理概要 #{Time.now - overall_start_time}" # 全体時間測定
  rescue => e
    ErrorUtility.log(e)
  end

  private

  def tweetable?(row)
    return true if row["last_tweeted_at"].nil? # last_tweeted_atがnilの場合はツイート可能

    last_tweeted_at = Time.parse(row["last_tweeted_at"])
    # tweet_intervalがnilの場合はデフォルトの30分、tweet_intervalが存在する場合は指定の値
    tweet_interval = row["tweet_interval"].nil? ? DEFAULT_TWEET_INTERVAL : row["tweet_interval"].to_i
    Time.now > last_tweeted_at + tweet_interval
  end

  def dynamo_db
    @dynamo_db ||= DynamoDb.new(TABLE_NAME)
  end

  def twitter_api
    @twitter_api ||= TwitterApi.new
  end

  def logger
    @logger ||= Logger.new('./logfile.log')
  end
end

CheckAmazonScript.new.execute if $PROGRAM_NAME == __FILE__