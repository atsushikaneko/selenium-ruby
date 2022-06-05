class TestTweetScript
  # ツイートできるかテストする
  def execute
    twitter_api = TwitterApi.new
    twitter_api.tweet("test again")
  end
end

TestTweetScript.new.execute if $PROGRAM_NAME == __FILE__