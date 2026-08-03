
Write-Host "🚀 Bootstrapping Local Serverless Architecture..." -ForegroundColor Cyan

$endpoint = "http://localhost:4566"
$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"
$env:AWS_DEFAULT_REGION = "us-east-1"

# 1. Create S3 Bucket
aws --endpoint-url=$endpoint s3 mb s3://raw-uploads | Out-Null
Write-Host "✔ S3 Bucket 'raw-uploads' created" -ForegroundColor Green

# 2. Create DynamoDB Table
aws --endpoint-url=$endpoint dynamodb create-table `
    --table-name processed-events `
    --attribute-definitions AttributeName=event_id,AttributeType=S `
    --key-schema AttributeName=event_id,KeyType=HASH `
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 | Out-Null
Write-Host "✔ DynamoDB Table 'processed-events' created" -ForegroundColor Green

# 3. Zip and Deploy Lambda Function
Compress-Archive -Path .\src\processor.py -DestinationPath .\processor.zip -Force
aws --endpoint-url=$endpoint lambda create-function `
    --function-name s3-processor `
    --runtime python3.10 `
    --handler processor.handler `
    --zip-file fileb://processor.zip `
    --role arn:aws:iam::000000000000:role/lambda-role | Out-Null
Write-Host "✔ Lambda Function 's3-processor' deployed" -ForegroundColor Green

# 4. Attach S3 Event Trigger to Lambda
$notificationConfig = @{
    LambdaFunctionConfigurations = @(
        @{
            LambdaFunctionArn = "arn:aws:lambda:us-east-1:000000000000:function:s3-processor"
            Events = @("s3:ObjectCreated:*")
        }
    )
} | ConvertTo-Json -Depth 4

$notificationConfig | Out-File -Encoding ascii notification.json
aws --endpoint-url=$endpoint s3api put-bucket-notification-configuration `
    --bucket raw-uploads `
    --notification-configuration file://notification.json | Out-Null
Remove-Item notification.json, processor.zip

Write-Host "🎉 Local Serverless Architecture is Live and ready!" -ForegroundColor Yellow