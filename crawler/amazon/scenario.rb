require 'selenium-webdriver'

module Crawler
  module Amazon
    class Scenario
      CART_SELLER_XPATH = '//*[@id="tabular-buybox"]/div[1]/div[4]/div/span/a'
      CART_PRICE_XPATH = '//*[@id="corePrice_desktop"]/div/table/tbody/tr[2]/td[2]/span[1]/span[1] | //*[@id="corePriceDisplay_desktop_feature_div"]/div[1]/span/span[1]'
      NORMAL_ORDER_RADIO_BUTTON_XPATH = '//*[@id="newAccordionRow"]/div/div[1]/a/i'
      LABEL_XPATH = '//*[@id="newAccordionCaption_feature_div"]/div/span'
    
      def initialize(start_url:, monitoring_target:, desired_arrival_amount:)
        @start_url = start_url
        @monitoring_target = monitoring_target
        @desired_arrival_amount = desired_arrival_amount
      end
    
      attr_reader :start_url, :monitoring_target, :desired_arrival_amount
    
      def item_in_stock_by_target_sellers?
        puts "start_url: #{start_url}"
        driver.navigate.to start_url
    
        # 定期便が存在する商品の場合、通常の注文を選択する
        click_normal_order_button
        # クリックしたあと少し待つ
        sleep(1)
    
        # カートセラーが取得できない場合はfalseを返す
        return false unless cart_seller_name = driver.find_elements(:xpath, CART_SELLER_XPATH)[0]&.text
        puts "cart_seller_name: #{cart_seller_name}"
        
        # カートセラーがAmazonの場合はtrueを返す
        # カートセラーがAmazon以外の場合は、指定価格以下ならtrueを返す
        if monitoring_target == "Amazon" && cart_seller_name == "Amazon.co.jp"
          puts '販売元はAmazon.co.jpです'
          return true
        elsif monitoring_target == "出店業者"
          puts '販売元はAmazon.co.jpではありません'
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
          options.add_argument('--no-sandbox')
          options.add_argument('--disable-dev-shm-usage')
          Selenium::WebDriver.for(:chrome , options: options).tap do |driver|
            driver.manage.timeouts.implicit_wait = 10 # 10秒待っても読み込まれない場合は、エラーが発生する
          end
        end
      end
    
      def click_normal_order_button
        radio_button = driver.find_elements(:xpath, NORMAL_ORDER_RADIO_BUTTON_XPATH)[0]
        radio_button.click if radio_button
      end
    end
  end
end