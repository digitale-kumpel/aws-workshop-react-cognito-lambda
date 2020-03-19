const AWS = require('aws-sdk')
const [,, username, role] = process.argv

const cognitoidentityserviceprovider = new AWS.CognitoIdentityServiceProvider({apiVersion: '2016-04-18', region: "eu-central-1"});

if (!username || !role) {
  console.error(`
  Role assign tool
  USAGE:

  rolista {username} {role}
  `)
  process.exit(1)
}

const params = {
  UserAttributes: [ 
    {
      Name: 'custom:nettrek_role',
      Value: role
    },
  ],
  UserPoolId: 'eu-central-1_3pACaZ1yT',
  Username: username,
};
cognitoidentityserviceprovider.adminUpdateUserAttributes(params, function(err, data) {
  if (err) console.log(err, err.stack); 
  else     console.log(data);
});