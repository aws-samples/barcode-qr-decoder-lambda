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

#set variables. Replace <BUCKET_NAME> with the name of your S3 bucket
LAYER_FOLDER_TREE=python/lib/python3.7/site-packages

#download and zip pillow layer
mkdir -p $LAYER_FOLDER_TREE
pip3 install pillow -t $LAYER_FOLDER_TREE
zip -r pillow_layer.zip python && rm -r python

#download pyzbar layer
mkdir -p $LAYER_FOLDER_TREE
pip3 install pyzbar -t $LAYER_FOLDER_TREE

#get shared library (libzbar.so) needed for pyzbar to work properly within the Lambda function
#compiling zbar to obtain libzbar.so
sudo yum install -y autoconf autopoint gettext-devel automake pkgconfig libtool
git clone https://github.com/mchehab/zbar.git
cd zbar/
autoreconf -vfi
./configure && make && cd

#copy library to layer folder and replace libzbar.so path inside zbar_library.py to correctly load the library. Lambda layers (.zips) will be uploaded to S3
cp zbar/zbar/.libs/libzbar.so.0.3.0 $LAYER_FOLDER_TREE/pyzbar/libzbar.so
sed -i "s/find_library('zbar')/('\/opt\/python\/lib\/python3.7\/site-packages\/pyzbar\/libzbar.so')/g" $LAYER_FOLDER_TREE/pyzbar/zbar_library.py
zip -r pyzbar_layer.zip python && rm -rf python && rm -rf zbar

#package lambda function code in a .zip
zip -r lambda_function.zip Barcode-QR-Decoder-Lambda/src/code/lambda_function.zip
aws s3 sync . s3://$BUCKET_NAME/BarcodeQRDecoder/qr-reader/assets --exclude="*" --include="*layer.zip" --include="lambda_function.zip"

#delete generated lambda layers after uploaded to S3 to clean curent directory
rm pillow_layer.zip pyzbar_layer.zip lambda_function.zip