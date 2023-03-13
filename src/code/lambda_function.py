import json, boto3, urllib, time
from pyzbar.pyzbar import decode
from urllib.parse import unquote_plus
from PIL import Image

print('Loading function')

s3 = boto3.client('s3')

def lambda_handler(event, context):
    print("Received file")
    print(event)
    # This function take the S3 bucket and key from the trigger event
    # If you wish to pass on your own image in the call you will have to update these values
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = unquote_plus(event['Records'][0]['s3']['object']['key'])
    print("Image to analyze: " + key)

    try:
        # The lambda function will download the S3 image into it's own tmp folder
        temp = '/tmp/{}'.format(str(time.time()))
        s3.download_file(bucket, key, temp)
        # Code extraction from image
        qr = decode(Image.open(temp))
        # We create a list in case multiple codes are detected
        data = []
        # print(qr)
        if (len(qr) > 0):
            for code in qr:
                print("Found link: " + (code.data).decode('UTF-8'))
                data.append((code.data).decode('UTF-8'))
            return {
                'statusCode': 200,
                'body': json.dumps(data)
            }
        else:
            print("No barcode/QR detected")
            return {
                'statusCode': 200,
                'body': "No barcode/QR detected"
            }

    except Exception as e:
        print(e)
        raise e