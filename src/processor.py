import json
import boto3
import os

# Connect to Floci AWS endpoint
AWS_ENDPOINT = os.environ.get("AWS_ENDPOINT_URL", "http://localhost:4566")
dynamodb = boto3.resource('dynamodb', endpoint_url=AWS_ENDPOINT, region_name='us-east-1')

def handler(event, context):
    table = dynamodb.Table('processed-events')
    
    for record in event.get('Records', []):
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        size = record['s3']['object']['size']
        
        # Write processed record to DynamoDB
        table.put_item(
            Item={
                'event_id': key,
                'bucket': bucket,
                'file_size_bytes': size,
                'status': 'PROCESSED'
            }
        )
        print(f"✅ Successfully processed {key} from {bucket}")
        
    return {"statusCode": 200, "body": json.dumps("Success")}
