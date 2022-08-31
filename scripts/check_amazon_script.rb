require './dynamo_db'
require 'parallel'
require './twitter_api'
require './crawler/amazon/scenario'
require './error_utility'

class CheckAmazonScript
  TABLE_NAME = 'amazon_item_list'.freeze
  DEFAULT_TWEET_INTERVAL_SECONDS = 1800.freeze # 1800秒(30分)

  def execute
    overall_start_time = current_time # 全体時間測定
    logger.info p "実行開始: #{overall_start_time}"

    # クロール対象商品: in_monitoringカラムがtrue & ツイートインターバル時間内でない商品
    logger.info p "クロール対象商品 #{target_rows_for_crawl.count}件"

    # rowsを絞る
    # p target_rows_for_crawl = target_rows_for_crawl[7..9]
    # p target_rows = [target_rows[7]]

    Parallel.each(target_rows_for_crawl, in_threads: 5) do |row|
      start_time = current_time # 個別時間測定
  
      scenaio = Crawler::Amazon::Scenario.new(
        start_url: row["start_url"],
        monitoring_target: row["monitoring_target"],
        desired_arrival_amount: row["desired_arrival_amount"].to_i,
      )

      begin 
        if scenaio.item_in_stock_by_target_sellers?
          logger.info p "ツイートします(#{row["asin"]})"
          logger.info p post_contents = row["post_contents"] + "\n\n" + current_time.strftime("%Y-%m-%d %H:%M:%S")
          twitter_api.tweet(post_contents)
          amazon_item_list.update(id: row["id"], column: "last_tweeted_at", value: current_time.to_s)
        end
      rescue => e
        ErrorUtility.log(e)
      end
  
      logger.info p "個別処理時間(#{row["asin"]}) #{current_time - start_time}s" # 個別時間測定
    end
  
    logger.info p "全体処理概時間 #{current_time - overall_start_time}s" # 全体時間測定
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
    current_time > last_tweeted_at + tweet_interval_seconds
  end

  def twitter_api
    @twitter_api ||= TwitterApi.new
  end

  def current_time
    # TODO: コンテナで実行時にUTCになるのを、32400秒(9時間)足して強引に日本時間に変換している。要修正
    Time.now + 32400
  end

  def logger
    @logger ||= Logger.new('./logfile.log')
  end
end

CheckAmazonScript.new.execute if $PROGRAM_NAME == __FILE__