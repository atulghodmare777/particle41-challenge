# particle41-challenge
TASK-1
Overview
SimpleTimeService is a minimalist web service that provides the current UTC timestamp and the IP address of the client making the request. It is built using Python and Flask, and containerized using Docker.

When accessed, the service responds with the following JSON format:
{
  "timestamp": "<current date and time>",
  "ip": "<the IP address of the visitor>"
}
Prerequisites
Before building and running the service, make sure you have the following tools installed:

Docker

Python

Git


Getting Started
Follow these steps to build, run, and test the SimpleTimeService.

1. Clone the Repository
Clone the project repository to your local machine:
git clone https://github.com/atulghodmare777/particle41-challenge.git

cd simple-time-service/app

2. Build the Docker Image
To build the Docker image, run the following command:
docker build -t simple-time-service .
docker run -d -p 5000:5000 --name simple-time-service simple-time-service

Above steps followed to create the image and run the image, and for testing if want to directly clone the image run use following command:
docker run -d -p 5000:5000 atulghodmare/simple-time-service:latest

Then to test run following command:
 curl http://localhost:5000 # Please make sure port 5000 is opened in the security group

 TASK-2
 clone the repository using following command:
 git clone https://github.com/atulghodmare777/particle41-challenge.git

 cd particle41-challenge/terraform

 Run following commands:
 terraform init
 terraform plan
 terraform apply

 After creation of eks cluster deploy the application using following commands:
 kubectl apply -f deployment.yaml
 kubectl apply -f service.yaml

 
