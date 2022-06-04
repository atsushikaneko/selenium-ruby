class TestTweetScript
  # ツイートできるかテストする
  def tweet
    twitter_api = TwitterApi.new
    twitter_api.tweet("test again")
  end
end