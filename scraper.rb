# selenium-webdriverを取り込む
require 'selenium-webdriver'
require './twitter_api'

class Scraper
  def initialize
    # ブラウザの指定(Chrome)
    @session = Selenium::WebDriver.for :chrome
    # 10秒待っても読み込まれない場合は、エラーが発生する
    session.manage.timeouts.implicit_wait = 10
  end

  attr_reader :session

  def execute(url)
    data1 = {desired_arrival_amount: 10000, monitoring_target: "amazon", post_content: "amazonのもの", start_url: "https://www.amazon.co.jp/gp/product/B079MCT7S5/?tag=sakurachecker-22&th=1"}
    data2 = {desired_arrival_amount: 10000, monitoring_target: "amazon", post_content: "出店業者のもの", start_url: "https://www.amazon.co.jp/%EF%BC%882%E3%82%B1%E3%83%BC%E3%82%B9%EF%BC%89%E6%98%8E%E6%B2%BB-%E3%82%B6%E3%83%90%E3%82%B9-SAVAS-%E3%83%9F%E3%83%AB%E3%82%AF%E3%83%97%E3%83%AD%E3%83%86%E3%82%A4%E3%83%B3-200ml%C3%9724%E6%9C%AC%E5%85%A5%C3%972%E3%82%B1%E3%83%BC%E3%82%B9/dp/B08YNHHTFL?pd_rd_w=cqNWq&pf_rd_p=cfde786c-3796-4675-b27f-944242fa9d28&pf_rd_r=MZS2MS9CMXSZWD00YKQB&pd_rd_r=71645dc5-d3f7-4a30-8329-1e5bd85a4014&pd_rd_wg=N0g9w&pd_rd_i=B08YNHHTFL&psc=1&ref_=pd_bap_d_rp_1_i"}
    data3 = {desired_arrival_amount: 1, monitoring_target: "amazon", post_content: "出店業者のもの", start_url: "https://www.amazon.co.jp/%EF%BC%882%E3%82%B1%E3%83%BC%E3%82%B9%EF%BC%89%E6%98%8E%E6%B2%BB-%E3%82%B6%E3%83%90%E3%82%B9-SAVAS-%E3%83%9F%E3%83%AB%E3%82%AF%E3%83%97%E3%83%AD%E3%83%86%E3%82%A4%E3%83%B3-200ml%C3%9724%E6%9C%AC%E5%85%A5%C3%972%E3%82%B1%E3%83%BC%E3%82%B9/dp/B08YNHHTFL?pd_rd_w=cqNWq&pf_rd_p=cfde786c-3796-4675-b27f-944242fa9d28&pf_rd_r=MZS2MS9CMXSZWD00YKQB&pd_rd_r=71645dc5-d3f7-4a30-8329-1e5bd85a4014&pd_rd_wg=N0g9w&pd_rd_i=B08YNHHTFL&psc=1&ref_=pd_bap_d_rp_1_i"}

    session.navigate.to url

    cart_seller = session.find_element(:xpath, '//*[@id="tabular-buybox"]/div[1]/div[4]').text
    puts cart_seller

    if cart_seller == "Amazon.co.jp"
      TwitterApi.new.tweet(data1[:post_content])
    else
      cart_price = session.find_element(:xpath, '//*[@id="corePrice_feature_div"]/div/span[1]/span[2]/span[2]').text
      puts cart_price

      if cart_price.to_i <= data2[:desired_arrival_amount]
        TwitterApi.new.tweet(data2[:post_content])
      end
    end
  rescue => e
    puts e
  ensure
    session.quit
  end
end

Scraper.new.execute("https://www.amazon.co.jp/%EF%BC%882%E3%82%B1%E3%83%BC%E3%82%B9%EF%BC%89%E6%98%8E%E6%B2%BB-%E3%82%B6%E3%83%90%E3%82%B9-SAVAS-%E3%83%9F%E3%83%AB%E3%82%AF%E3%83%97%E3%83%AD%E3%83%86%E3%82%A4%E3%83%B3-200ml%C3%9724%E6%9C%AC%E5%85%A5%C3%972%E3%82%B1%E3%83%BC%E3%82%B9/dp/B08YNHHTFL?pd_rd_w=cqNWq&pf_rd_p=cfde786c-3796-4675-b27f-944242fa9d28&pf_rd_r=MZS2MS9CMXSZWD00YKQB&pd_rd_r=71645dc5-d3f7-4a30-8329-1e5bd85a4014&pd_rd_wg=N0g9w&pd_rd_i=B08YNHHTFL&psc=1&ref_=pd_bap_d_rp_1_i")