require 'selenium-webdriver'
require './constants/user_agent_list'
require './constants/proxy_list'

module Crawler
  module Amazon
    class Scenario
      CART_SELLER_XPATH = '//*[@id="tabular-buybox"]/div[1]/div[4]/div/span/a'
      CART_PRICE_XPATH = '//*[@id="corePrice_desktop"]/div/table/tbody/tr[2]/td[2]/span[1]/span[1] | //*[@id="corePriceDisplay_desktop_feature_div"]/div[1]/span/span[1]'
      NORMAL_ORDER_RADIO_BUTTON_XPATH = '//*[@id="newAccordionRow"]/div/div[1]/a/i'
      LABEL_XPATH = '//*[@id="newAccordionCaption_feature_div"]/div/span'
      OTHER_SELLERS_LIST_LINK_XPATH = '//*[@id="olpLinkWidget_feature_div"]/div[2]/span/a/div/div/span[1]'
      OTHER_SELLER_NAMES_XPATH = '//*[@id="aod-offer-soldBy"]/div/div/div[2]/a'
  
    
      def initialize(start_url:, monitoring_target:, desired_arrival_amount:)
        @start_url = start_url
        @monitoring_target = monitoring_target
        @desired_arrival_amount = desired_arrival_amount
      end
    
      attr_reader :start_url, :monitoring_target, :desired_arrival_amount
    
      def item_in_stock_by_target_sellers?
        logger.info p "start_url: #{start_url}"
        # log_current_ip
        
        driver.navigate.to start_url
    
        # 定期便が存在する商品の場合、通常の注文を選択する
        click_normal_order_button_if_exists
        # クリックしたあと少し待つ
        sleep(1)
    
        # カートセラーが取得できない場合はfalseを返す
        return false unless cart_seller_name = driver.find_elements(:xpath, CART_SELLER_XPATH)[0]&.text
        logger.info p "cart_seller_name: #{cart_seller_name}"
        
        # 監視対象がAmazonかつ、カートセラーがAmazonの場合はtrueを返す
        # 監視対象が出店業者かつ、カートセラーがAmazon以外の場合は、指定価格以下ならtrueを返す
        if monitoring_target == "Amazon" && cart_seller_name == "Amazon.co.jp"
          logger.info p '販売元はAmazon.co.jpです'
          return true
        elsif monitoring_target == "Amazon"
          driver.find_elements(:xpath, OTHER_SELLERS_LIST_LINK_XPATH)[0]&.click
          sleep(1)
          serller_names = driver.find_elements(:xpath, OTHER_SELLER_NAMES_XPATH).map{ |e| e&.text }
          return serller_names.include?("Amazon.co.jp")

        elsif monitoring_target == "出店業者"
          logger.info p '販売元はAmazon.co.jpではありません'
          cart_price = driver.find_element(:xpath, CART_PRICE_XPATH).text.delete("￥").to_i
          return true if cart_price <= desired_arrival_amount
        end

        false
      ensure
        driver.quit
      end
    
      private

      def driver
        @driver ||= begin
          options = Selenium::WebDriver::Chrome::Options.new
          options.add_argument('--headless') # ヘッドレスモードでの実行の場合コメントイン
          options.add_argument('--no-sandbox') # コンテナ内で実行する場合はコメントイン
          options.add_argument('--disable-dev-shm-usage') # コンテナ内で実行する場合はコメントイン
          options.add_argument("--user-agent=#{USER_AGENT_LIST.sample}")
          options.add_argument("--proxy-server=http://#{PROXY_LIST.sample}")
          Selenium::WebDriver.for(:chrome , options: options).tap do |driver|
            driver.manage.timeouts.implicit_wait = 2
          end
        end
      end

      def log_current_ip
        driver.navigate.to "https://www.cman.jp/network/support/go_access.cgi"
        ip = driver.find_elements(:xpath, '//*[@id="tmContHeadStr"]/div/div[1]/div[3]/div[1]')[0]&.text
        sleep(1)
        logger.info p "ip: #{ip}"
      end
    
      def click_normal_order_button_if_exists
        radio_button = driver.find_elements(:xpath, NORMAL_ORDER_RADIO_BUTTON_XPATH)[0]
        radio_button.click if radio_button
      end

      def logger
        @logger ||= Logger.new('./logfile.log')
      end
    end
  end
end