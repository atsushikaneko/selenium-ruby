require './dynamo_db'
require 'parallel'
require './twitter_api'
require './crawler/amazon/scenario'
require './error_utility'

class CheckAmazonScript
  TABLE_NAME = 'amazon_item_list'.freeze
  DEFAULT_TWEET_INTERVAL_SECONDS = 1800.freeze # 1800秒(30分)

  def execute
    p "実行開始"
    logger.info "実行開始: #{Time.now}"
    overall_start_time = Time.now # 全体時間測定

    # クロール対象商品: in_monitoringカラムがtrue & ツイートインターバル時間内でない商品
    p "クロール対象商品 #{target_rows_for_crawl.count}件"

    # rowsを絞る
    # p target_rows_for_crawl = target_rows_for_crawl[7..9]
    # p target_rows = [target_rows[7]]

    target_rows_for_tweet = []
    Parallel.each(target_rows_for_crawl, in_threads: 5) do |row|
      start_time = Time.now # 個別時間測定
  
      scenaio = Crawler::Amazon::Scenario.new(
        start_url: row["start_url"],
        monitoring_target: row["monitoring_target"],
        desired_arrival_amount: row["desired_arrival_amount"].to_i,
      )
      target_rows_for_tweet << row if scenaio.item_in_stock_by_target_sellers?
  
      p "個別処理時間 #{Time.now - start_time}s" # 個別時間測定
    end
  
    target_rows_for_tweet.each do |row|
      p "ツイートします"
      p post_contents = row["post_contents"] + "\n\n(#{Time.now.to_s})"
      twitter_api.tweet(post_contents)

      amazon_item_list.update(id: row["id"], column: "last_tweeted_at", value: Time.now.to_s)
      sleep(rand(10..30))
    end
  
    p "全体処理概時間 #{Time.now - overall_start_time}s" # 全体時間測定
  rescue => e
    ErrorUtility.log(e)
  end

  private

  # クロール対象商品: in_monitoringカラムがtrue & ツイートインターバル時間内でない商品
  def target_rows_for_crawl
    @crawl_target_rows ||= begin
      monitoring_rows = amazon_item_list.all.select{ |row| row["is_monitoring"] == "true" }
      monitoring_rows.select{ |row| outside_tweet_interval?(row) }
    end
  end

  def amazon_item_list
    @amazon_item_list ||= DynamoDb.new(TABLE_NAME)
  end

  def outside_tweet_interval?(row)
    return true if row["last_tweeted_at"].nil? # last_tweeted_atがnilの場合はツイート可能

    last_tweeted_at = Time.parse(row["last_tweeted_at"])
    # tweet_intervalがnilの場合はデフォルトの30分、tweet_intervalが存在する場合は指定の値
    tweet_interval_seconds = row["tweet_interval_minutes"].nil? ? DEFAULT_TWEET_INTERVAL_SECONDS : (row["tweet_interval_minutes"].to_i * 60)
    Time.now > last_tweeted_at + tweet_interval_seconds
  end

  def twitter_api
    @twitter_api ||= TwitterApi.new
  end

  def logger
    @logger ||= Logger.new('./logfile.log')
  end
end

CheckAmazonScript.new.execute if $PROGRAM_NAME == __FILE__