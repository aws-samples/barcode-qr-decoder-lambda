import json, boto3, pandas, tempfile, time, os
from pyzbar.pyzbar import decode
from pdf2image import convert_from_path
from datetime import datetime
from sqlalchemy import create_engine
from urllib.parse import unquote_plus

DB_USER = os.environ('DB_USER')
DB_PASSWORD = os.environ('DB_PASSWORD')
DB_HOST = os.environ('DB_HOST')
DB_DATABASE = os.environ('DB_DATABASE')
DB_STR = f'mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}/{DB_DATABASE}'
S3 = boto3.client('s3')

def check_doc_type_letter(letters: str) -> bool:
    if len(letters) >= 1:
        return True
    return False

def check_reference(reference: str) -> bool:
    if len(reference) == 14:
        return True
    return False

def check_entity_letter(letter: str) -> bool:
    if len(letter) == 1:
        return True
    return False

def check_list_values(data: list) -> bool:
    return len(data) == 3 and check_doc_type_letter(data[0]) and check_reference(data[1]) and check_entity_letter(data[2])

def insert_to_db(data: dict) -> None:  
    insert_df = pandas.DataFrame(data=[data])
    db = create_engine(DB_STR)
    insert_df.to_sql(con=db, name='DocumentQrDecode', if_exists='append', index=False, method='multi')

def lambda_handler(event, context):
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = unquote_plus(event['Records'][0]['s3']['object']['key'])
    doc_name = key.split('/')[-1]
    str_datetime_now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    decoded = 0
    try: 
        temp = '/tmp/{}'.format(str(time.time()))
        S3.download_file(bucket, key, temp)
        with tempfile.TemporaryDirectory() as path:
            images_from_path = convert_from_path(temp, output_folder=path)
        for key, image in images_from_path:
            data = {}
            data['document_id'] = doc_name.split('-')[0]
            data['documentTmpName'] = image.filename
            data['decoded'] = 0
            qr = decode(image)
            if (len(qr) > 0):
                for code in qr:
                    data_list = code.data.decode('UTF-8').split(' ')
                    if len(data_list) > 2 and check_list_values(data_list):
                        decoded = 1
                        data['decodedAt'] = str_datetime_now
                        data['updatedAt'] = str_datetime_now
                        data['documentTypeLetters'] = data_list[0]
                        data['reference'] = data_list[1]
                        data['entityLetter'] = data_list[2]

            data['decoded'] = decoded
            data['updatedAt'] = str_datetime_now
            data['createdAt'] = str_datetime_now
            if True == decoded or key + 1 == len(images_from_path):
                insert_to_db(data)
                return {
                    'statusCode': 200,
                    'body': json.dumps(data)
                }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(e)
        }       

