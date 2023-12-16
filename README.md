![Banner](src/img/banner.png)
Easily decode barcodes and QR codes at scale with AWS Lambda!
With this Lambda Function you will be able to add decoding features to your applications at scale!

### What do I need?
**AWS Account** If you don't already have an account or you have not been handed one as part of a workshop, please visit the following [link](https://portal.aws.amazon.com/billing/signup?nc2=h_ct&src=header_signup&redirect_url=https%3A%2F%2Faws.amazon.com%2Fregistration-confirmation#/start)! 

### How can I read QR codes with AWS Lambda?

#### Step 1. Create an Amazon S3 bucket. 
* **You will need to have an Amazon S3 Bucket created.**
* **You will need to create a folder inside that bucket, where you will upload your images to decode.(Optional)**

#### Step 2, Generate code artifacts and dependencies
To read QR/Barcodes, we are going to be using the [Zbar library](https://github.com/mchehab/zbar), an open source software suite for reading bar codes. We are going to include Zbar and other necessary packages into Lambda Layers for our Lambda function to work.
But don't worry, we have already automated this process for you, in a simple script you can run in your AWS Cloud9! Here are the steps you have to follow:

* Login into you AWS Account and access AWS Cloud9 by navigating to https://console.aws.amazon.com/cloud9control/home#/

* Click on "Create environment"

* Provide a name for your environment, select an instance from the t2 or t3 family and make sure to choose "Amazon Linux 2" as platform. This guarantees the correct installation of the zbar library

![Cloud9Setup1](src/img/cloud9_step-1.png)

* We recommend to choose "AWS Systems Manager(SSM)" in the network settings as it won't require you to open any inbound port to the EC2 instance. Do not change setting in the "VPC Settings" sections unless you need to. Finally, create the environment by clicking "Create"

![Cloud9Setup2](src/img/cloud9_step-2.png)

* Once your Cloud9 environment is created, open it and create a new terminal

![Cloud9Setup3](src/img/cloud9_step-3.png)

* Now clone this repo 
   * `git clone https://github.com/aws-samples/barcode-qr-decoder-lambda.git`


* Run the `setup.sh` script in order to generate the needed lambda layers and code package. You must specify the bucket where you want to upload this artifacts replacing <BUCKET_NAME> with the S3 bucket name you created.
   * `sh barcode-qr-decoder-lambda/src/code/setup.sh -b <BUCKET_NAME>`


* Once the script finishes, you should see 2 new files in your S3 bucket under `BarcodeQRDecoder/qr-reader/assets/` path, the Lambda layer containing the libraries needed (Pillow and Pyzbar) and the lambda code packaged in a .zip file

![S3Files](src/img/step-0_2.png)

#### Step 3, Create your Lambda function

* Create a new Lambda Function.
* Select Author from scratch.
* Input a new name for your function
* Select Python 3.9 as runtime
* Select x86_64 as architecture
* Create a new role with basic Lambda permissions
* Replace the code with Python code [available in this repository](src/code/lambda_function.py)

You have now created the Lambda function!

#### Step 4, Add Layers to your Lambda function
As we mentioned before, your function needs some packages to run correctly. If you completed step 2, you should have the layer artifact ready in your bucket!
Follow these steps to create your layer:
  - Open the Layers page of the Lambda console. 
  - Choose Create layer.
  - Under Layer configuration, for Name, enter a name for your layer.
  - (Optional) For Description, enter a description for your layer.
  - To upload a file from Amazon S3, choose Upload a file from Amazon S3. Then, for Amazon S3 link URL, enter the S3 URI of the artifact.
  - For Compatible architectures, choose x86_64.
  - For Compatible runtimes, choose Python 3.9.
  - Choose Create.

Next, go to the Lambda function and in your layers section, select Add Layer. Select your layer which will be available at the Custom AWS layers dropdown.

#### Step 5, Configure the permissions needed
Head over to IAM and add permissions to your associated role to access your S3 Bucket.

You can find your role in the Configuration --> Permissions tab in the function editor.

Also, increase your lambda timeout to 60 seconds in the function configuration.

#### Step 6, Configure your Amazon S3 Trigger event
* Once you open your new Lambda Function, head over to the **Function overview** panel and click on **Add trigger**.

![Add Event](src/img/step-3.png)  

* Select **S3** from the trigger list.
* Select the S3 bucket where you will be uploading your files.
* Select **All object create events**.
* If you want to add prefix to specify a folder you can also add it.

![Event Info](src/img/step-4.png)  

* Once you have configured all parameters, **Add** the trigger. 

![Event Completed](src/img/step-5.png) 

#### Step 7, Try out your Lambda Function
You are now ready to add Barcode/QR code decoding capabilities to your applications at scale!
Simply add an image with a QR to your S3 bucket folder you specified earlier. 
You can see the logs your lambda function returns in the CloudWatch Logs console.

![Test](src/img/step-6.png)


## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

