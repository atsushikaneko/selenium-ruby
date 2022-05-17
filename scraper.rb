# selenium-webdriverを取り込む
require 'selenium-webdriver'
require './twitter_api'
require './dynamo_db'
require 'parallel'

class Crawler
  CART_SELLER_XPATH = '//*[@id="tabular-buybox"]/div[1]/div[4]/div/span/a'
                      #  //*[@id="tabular-buybox"]/div[1]/div[4]/div/span/a
  # CART_SELLER_XPATH = '//*[@id="tabular-buybox"]/div[1]/div[4] | //*[@id="tabular-buybox"]/div[1]/div[4]/div/span/a'
  # //*[@id="tabular-buybox"]/div[1]/div[4]/div
  CART_PRICE_XPATH = '//*[@id="corePrice_desktop"]/div/table/tbody/tr[2]/td[2]/span[1]/span[1] | //*[@id="corePriceDisplay_desktop_feature_div"]/div[1]/span/span[1]'
  # CART_PRICE_XPATH2 = '//*[@id="corePrice_feature_div"]/div/span[1]/span[2]'
  NORMAL_ORDER_RADIO_BUTTON_XPATH = '//*[@id="newAccordionRow"]/div/div[1]/a/i'
  LABEL_XPATH = '//*[@id="newAccordionCaption_feature_div"]/div/span'

  def initialize(start_url:, desired_arrival_amount:, post_content:)
    @start_url = start_url
    @desired_arrival_amount = desired_arrival_amount
    @post_content = post_content
    # ブラウザの指定(Chrome)
    @driver = Selenium::WebDriver.for :chrome
    # 10秒待っても読み込まれない場合は、エラーが発生する
    driver.manage.timeouts.implicit_wait = 10
  end

  # //*[@id="corePrice_desktop"]/div/table/tbody/tr[2]/td[2]/span[1]/span[1]
  # //*[@id="corePriceDisplay_desktop_feature_div"]/div[1]/span/span[1]

  attr_reader :start_url, :desired_arrival_amount, :post_content, :driver

  def item_meets_condition?
    puts start_url
    driver.navigate.to start_url
    puts "start_url: #{start_url}"

    # 定期便が存在する商品の場合、通常の注文を選択する
    # click_normal_order_button

    cart_seller = driver.find_elements(:xpath, CART_SELLER_XPATH)
    puts cart_seller.class
    puts cart_seller[0].text
    # puts cart_seller.value
    puts cart_seller.inspect
    puts "cart_seller: #{cart_seller}"
    
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
    @logger ||= logger = Logger.new('./logfile.log')
  end
end

rows = DynamoDb.new.all
puts rows[1]["start_url"]
row = rows[1]

puts "投稿内容: #{row["post_contents"]}"
# TwitterApi.new.tweet(row["post_contents"]) if crawler.item_meets_condition?

arr = []
4.times { arr << row[10] }
puts arr


def main
  tweetable_rows = []

  Parallel.each(arr, in_threads: 5) do |row|
    crawler = Crawler.new(
      start_url: row["start_url"],
      desired_arrival_amount: row["desired_arrival_amount"].to_i,
      post_content: row["post_contents"]
    )
    tweetable_rows << row if crawler.item_meets_condition?
  end

  if tweetable_rows.any?
  twitter_api  = TwitterApi.new

  tweetable_rows.each do |row|
    twitter_api.tweet(row["post_content"])
    sleep(5)
  end
rescue => e
  puts e
  puts e.backtrace
  logger.error e.class
  logger.error e.message
end