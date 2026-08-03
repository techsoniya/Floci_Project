import boto3
import json
import time

ENDPOINT = "http://localhost:4566"

s3 = boto3.client('s3', endpoint_url=ENDPOINT, region_name='us-east-1', aws_access_key_id='test', aws_secret_access_key='test')
dynamo = boto3.resource('dynamodb', endpoint_url=ENDPOINT, region_name='us-east-1', aws_access_key_id='test', aws_secret_access_key='test')

print("📤 Dropping sample file into local S3 bucket...")
s3.put_object(Bucket="raw-uploads", Key="sales_report_2026.json", Body=json.dumps({"sales": 15000}))

print("⚡ Waiting 1 second for Lambda event execution...")
time.sleep(1)

print("🔍 Checking DynamoDB for auto-processed record...")
table = dynamo.Table('processed-events')
response = table.get_item(Key={'event_id': 'sales_report_2026.json'})

if 'Item' in response:
    print("🎉 SUCCESS! Local Event-Driven Pipeline Executed Perfectly:")
    print(json.dumps(response['Item'], indent=2))
else:
    print("❌ Item not found yet.")
    