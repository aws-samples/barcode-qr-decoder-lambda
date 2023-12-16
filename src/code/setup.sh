#!/bin/bash

#check input parameter (usage: sh setup.sh -b <BUCKET_NAME>)
while getopts b: params
do 
    case "${params}"
        in
        b)BUCKET_NAME=${OPTARG};;
    esac
done

if [ -z "$BUCKET_NAME" ]
    then echo "No S3 bucket provided. Usage: sh setup.sh -b <BUCKET_NAME>"
    exit 0
fi

#download python 3.9
wget https://www.python.org/ftp/python/3.9.18/Python-3.9.18.tgz
tar xvf Python-3.9.18.tgz && cd Python-3.9.18
./configure --enable-optimizations && sudo make altinstall && cd 

#create and activate python venv
python3.9 -m venv .venv && source .venv/bin/activate

#set variables. Replace <BUCKET_NAME> with the name of your S3 bucket
LAYER_FOLDER_TREE=python/lib/python3.9/site-packages

#download and zip pillow layer
mkdir -p $LAYER_FOLDER_TREE
pip install pillow -t $LAYER_FOLDER_TREE
#zip -r pillow_layer.zip python && rm -r python

#download pyzbar layer
mkdir -p $LAYER_FOLDER_TREE
pip install pyzbar -t $LAYER_FOLDER_TREE

#get shared library (libzbar.so) needed for pyzbar to work properly within the Lambda function
#compiling zbar to obtain libzbar.so
sudo yum install -y autoconf autopoint gettext-devel automake pkgconfig libtool
git clone https://github.com/mchehab/zbar.git
cd zbar/
autoreconf -vfi
./configure --with-gtk=auto --with-python=auto && make && cd

#copy library to layer folder and replace libzbar.so path inside zbar_library.py to correctly load the library. Lambda layers (.zips) will be uploaded to S3
cp zbar/zbar/.libs/libzbar.so.0.3.0 $LAYER_FOLDER_TREE/pyzbar/libzbar.so
sed -i "s/find_library('zbar')/('\/opt\/python\/lib\/python3.9\/site-packages\/pyzbar\/libzbar.so')/g" $LAYER_FOLDER_TREE/pyzbar/zbar_library.py
zip -r barcode_layer.zip python && rm -rf python && rm -rf zbar

#package lambda function code in a .zip
zip -r lambda_function.zip Barcode-QR-Decoder-Lambda/src/code/lambda_function.zip
#aws s3 sync . s3://$BUCKET_NAME/BarcodeQRDecoder/qr-reader/assets --exclude="*" --exclude=".c9*" --include="*layer.zip" --include="lambda_function.zip"
#aws s3 sync . s3://$BUCKET_NAME/BarcodeQRDecoder/qr-reader/assets --include="*.zip"

aws s3 cp barcode_layer.zip s3://$BUCKET_NAME/BarcodeQRDecoder/qr-reader/assets
aws s3 cp lambda_function.zi s3://$BUCKET_NAME/BarcodeQRDecoder/qr-reader/assets


#delete generated lambda layers after uploaded to S3 to clean curent directory
#rm pillow_layer.zip pyzbar_layer.zip lambda_function.zip
