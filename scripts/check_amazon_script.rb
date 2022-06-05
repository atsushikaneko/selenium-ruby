require './dynamo_db'
require 'parallel'
require './twitter_api'
require './crawler/amazon/scenario'
require './error_utility'

class CheckAmazonScript
  TABLE_NAME = 'amazon_item_list'.freeze
  DEFAULT_TWEET_INTERVAL = 1800.freeze # 1800秒(30分)

  def execute
    p "実行開始"
    overall_start_time = Time.now # 全体時間測定

    rows = dynamo_db.all
    # rowsを絞る
    p rows = rows[7..9]
    # p rows = [rows[7]]

    target_rows = []
    Parallel.each(rows, in_threads: 5) do |row|
      start_time = Time.now # 個別時間測定

      unless tweetable?(row)
        p "ツイートインターバル内なのでツイートできません"
        p "個別処理概要 #{Time.now - start_time}s" # 個別時間測定
        next
      end
  
      scenaio = Crawler::Amazon::Scenario.new(
        start_url: row["start_url"],
        monitoring_target: row["monitoring_target"],
        desired_arrival_amount: row["desired_arrival_amount"].to_i,
      )
      target_rows << row if scenaio.item_in_stock_by_target_sellers?
  
      p "個別処理概要 #{Time.now - start_time}s" # 個別時間測定
    end
  
    target_rows.each do |row|
      p "ツイートします"
      p post_contents = row["post_contents"] + "\n(#{Time.now.to_s})"
      twitter_api.tweet(post_contents)

      dynamo_db.update(id: row["id"], column: "last_tweeted_at", value: Time.now.to_s)
      sleep(rand(10..30))
    end
  
    p "全体処理概要 #{Time.now - overall_start_time}s" # 全体時間測定
  rescue => e
    ErrorUtility.log(e)
  end

  private

  def tweetable?(row)
    return true if row["last_tweeted_at"].nil? # last_tweeted_atがnilの場合はツイート可能

    last_tweeted_at = Time.parse(row["last_tweeted_at"])
    # tweet_intervalがnilの場合はデフォルトの30分、tweet_intervalが存在する場合は指定の値
    tweet_interval = row["tweet_interval"].nil? ? DEFAULT_TWEET_INTERVAL : (row["tweet_interval"].to_i * 60)
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