# selenium-webdriverを取り込む
require 'selenium-webdriver'
require './twitter_api'
require './dynamo_db'
require 'parallel'

module Crawler
  module Amazon
    class Scenario
      CART_SELLER_XPATH = '//*[@id="tabular-buybox"]/div[1]/div[4]/div/span/a'
      CART_PRICE_XPATH = '//*[@id="corePrice_desktop"]/div/table/tbody/tr[2]/td[2]/span[1]/span[1] | //*[@id="corePriceDisplay_desktop_feature_div"]/div[1]/span/span[1]'
      NORMAL_ORDER_RADIO_BUTTON_XPATH = '//*[@id="newAccordionRow"]/div/div[1]/a/i'
      LABEL_XPATH = '//*[@id="newAccordionCaption_feature_div"]/div/span'
    
      def initialize(start_url:, desired_arrival_amount:, post_content:)
        @start_url = start_url
        @desired_arrival_amount = desired_arrival_amount
        @post_content = post_content
        # ヘッドレスモードの場合以下コメントイン
        options = Selenium::WebDriver::Chrome::Options.new
        options.add_argument('--headless')
        @driver = Selenium::WebDriver.for :chrome , options: options
        # ヘッドレスモードじゃない場合は以下コメントイン
        # @driver = Selenium::WebDriver.for :chrome
        # driver.manage.timeouts.implicit_wait = 10 # 10秒待っても読み込まれない場合は、エラーが発生する
      end
    
      attr_reader :start_url, :desired_arrival_amount, :post_content, :driver
    
      def item_in_stock_by_target_sellers?
        driver.navigate.to start_url
        puts "start_url: #{start_url}"
    
        # 定期便が存在する商品の場合、通常の注文を選択する
        click_normal_order_button
        # クリックしたあと少し待つ
        sleep(1)
    
        return false unless cart_seller = driver.find_elements(:xpath, CART_SELLER_XPATH)[0]&.text
        puts "cart_seller: #{cart_seller}"
        
        # カートセラーがAmazonの場合はtrue
        # カートセラーがAmazon意外の場合は、指定価格以下ならtrue
        if cart_seller == "Amazon.co.jp"
          puts '販売元はAmazon.co.jpです'
          return true
        else
          puts '販売元はAmazon.co.jpではありません'
          cart_price = driver.find_element(:xpath, CART_PRICE_XPATH).text.delete("￥").to_i
          puts cart_price.class
          if cart_price <= desired_arrival_amount
            return true
          end
        end

      ensure
        driver.quit
      end
    
      private
    
      def click_normal_order_button
        radio_button = driver.find_elements(:xpath, NORMAL_ORDER_RADIO_BUTTON_XPATH)[0]
        radio_button.click if radio_button
      end
    
      def logger
        @logger ||= Logger.new('./logfile.log')
      end
    end
  end
end

# TWEET_INTERVAL = 1800.freeze # 1800秒
TWEET_INTERVAL = 0.freeze # 1800秒
def tweetable?(row)
  # last_tweeted_atがnilの場合はツイート可能
  return true if row["last_tweeted_at"] == nil

  last_tweeted_at = Time.parse(row["last_tweeted_at"])
  Time.now > last_tweeted_at + TWEET_INTERVAL
end

def main
  dynamo_db = DynamoDb.new('amazon_item_list')
  rows = dynamo_db.all
  # rowsを絞る
  # puts rows = rows[0..4]
  # puts rows = [rows[0]]

  whole_start_time = Time.now # 全体時間測定

  logger = Logger.new('./logfile.log')
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
        # twitter_api.tweet(row["post_content"])
        dynamo_db.update(id: row["id"], column: "last_tweeted_at", value: Time.now.to_s)
      # sleep(2)
      end
    end

    p "全体処理概要 #{Time.now - whole_start_time}s" # 時間測定
  end

rescue => e
  puts e.class
  puts e.message
  puts e.backtrace
  logger.error e.class
  logger.error e.message
  logger.error e.backtrace
end

main