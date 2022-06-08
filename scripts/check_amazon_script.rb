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

    p "監視対象 #{target_rows.count}件"
    # rowsを絞る
    p target_rows = target_rows[7..9]
    # p target_rows = [target_rows[7]]

    target_rows = []
    Parallel.each(target_rows, in_threads: 5) do |row|
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
      p post_contents = row["post_contents"] + "\n\n(#{Time.now.to_s})"
      twitter_api.tweet(post_contents)

      amazon_item_list.update(id: row["id"], column: "last_tweeted_at", value: Time.now.to_s)
      sleep(rand(10..30))
    end
  
    p "全体処理概要 #{Time.now - overall_start_time}s" # 全体時間測定
  rescue => e
    ErrorUtility.log(e)
  end

  private

  # 監視対象の行
  def target_rows
    @target_rows ||= amazon_item_list.all.select{|row| row["is_monitoring"] == "true" }
  end

  def amazon_item_list
    @amazon_item_list ||= DynamoDb.new(TABLE_NAME)
  end

  def tweetable?(row)
    return true if row["last_tweeted_at"].nil? # last_tweeted_atがnilの場合はツイート可能

    last_tweeted_at = Time.parse(row["last_tweeted_at"])
    # tweet_intervalがnilの場合はデフォルトの30分、tweet_intervalが存在する場合は指定の値
    tweet_interval = row["tweet_interval"].nil? ? DEFAULT_TWEET_INTERVAL : (row["tweet_interval"].to_i * 60)
    Time.now > last_tweeted_at + tweet_interval
  end

  def twitter_api
    @twitter_api ||= TwitterApi.new
  end

  def logger
    @logger ||= Logger.new('./logfile.log')
  end
end

CheckAmazonScript.new.execute if $PROGRAM_NAME == __FILE__