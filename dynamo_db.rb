require 'aws-sdk-dynamodb'

# dynamodb = Aws::DynamoDB::Client.new(
#     region: region_name,
#     credentials: credentials,
# )

# client = Aws::DynamoDB::Client.new(
#     access_key_id: ENV['AWS_ACCESS_KEY_ID'],
#     secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
#     region: ENV['AWS_REGION']
# )

# puts client.scan(table_name: "amazon_item_list").to_a

class DynamoDb
  def initialize
    @client = Aws::DynamoDB::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )
  end

  attr_reader :client

  def all
    client.scan(table_name: "amazon_item_list").to_a
  end
end