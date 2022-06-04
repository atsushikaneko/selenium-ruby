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
  def initialize(table_name)
    @table_name = table_name
  end

  def all
    client.scan(table_name: @table_name)["items"].to_a
  end

  def update(id:, column:, value:)
    client.update_item({
      table_name: @table_name,
      key: {
        id: "#{id}",
      },
      update_expression: "SET #{column} = :val",
      expression_attribute_values: {
        ':val' => value,
      }
    })
  end

  private
  
  def client
    @client ||= Aws::DynamoDB::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )
  end
end