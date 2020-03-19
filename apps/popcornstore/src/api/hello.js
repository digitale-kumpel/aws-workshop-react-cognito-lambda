import AWS from 'aws-sdk'

export const createClient = ({ AccessKeyId, SecretKey, SessionToken}) => {
  const lambda = new AWS.Lambda({ region: "eu-central-1", accessKeyId: AccessKeyId, sessionToken: SessionToken, secretAccessKey: SecretKey})
  return lambda
}

export default async(client) => {
    return client.invoke({
      FunctionName: "nettrek-backend-popcorn"
    }).promise()
  }