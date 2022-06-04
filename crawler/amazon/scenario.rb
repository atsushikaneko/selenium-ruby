require 'selenium-webdriver'

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
    end
  end
end