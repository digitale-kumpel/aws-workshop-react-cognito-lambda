import Amplify from 'aws-amplify';

Amplify.configure({
  Auth: {
      identityPoolId: 'eu-central-1:bfca9f3d-3b1c-4f91-9512-dfde7472d4fa',
      region: 'eu-central-1',
      userPoolId: 'eu-central-1_3pACaZ1yT',
      userPoolWebClientId: '4050o1sdggubpu8pfbaq7ce5sf',
      mandatorySignIn: false,
  }
});