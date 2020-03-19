# Workshop Example

This example implements an AWS infrastructure using terraform. It contains two simple react apps, cognito for user authentication and authorization and a simple lambda backend function that is called directly from the client.

## Init terraform
Login to your aws account, for example by using `aws-vault login [YOURPROFILE]` and create a state bucket on your AWS, like `state.my.domain` and replace `terraform.backend.bucket` in `infra/main.ts` with this bucket. 
Then replace the variables in `variable.ts` with appropriate values for your project. 
After that run `terraform init` to download dependencies. Then rund `terraform plan` to see a list of all steps terraform will take to deploy your infrastructure. To actualy deploy run `terraform apply` and after carefuly reading type `YES`.

## Setup the infrastructure

## Init apps
You need to install all dependencies

```javascript
cd apps/ticketstore
npm install
// same for popcornstore
```

## Deploy react app

First you need to build the app:

```javascript
cd apps/ticketstore
npm install // if new deps or not done yet
npm run build
aws-vault exec YOUR_PROFILE -- npm run deploy
```

In `apps/popcornstore` and `apps/ticketstore` you can run `npm run deploy` in order to copy the build to the s3 bucket, specified in terraform.



## TODOS
- do not use strings to reference entities in infra/main.tf
- create a module for react app hosting including cdn
