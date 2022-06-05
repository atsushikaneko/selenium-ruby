# 執筆時点での最新
FROM ruby:2.7.6

# Chrome をインストール
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add \
  && echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | tee /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update -qq \
  && apt-get install -y google-chrome-stable libnss3 libgconf-2-4

# ChromeDriver をインストール
# 現在の最新のバージョンを取得し、それをインストールする。
RUN CHROMEDRIVER_VERSION=`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE` \
  && curl -sS -o /tmp/chromedriver_linux64.zip http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip \
  && unzip /tmp/chromedriver_linux64.zip \
  && mv chromedriver /usr/local/bin/

## 下記以降はよしなに

# スクレイピング用の Ruby ソースコードをコピー(任意)
# Gemfile では `selenium-webdriver` をインストールしている。
WORKDIR /app
COPY Gemfile /app
COPY Gemfile.lock /app
RUN bundle install

COPY . /app