import { withAuthenticator } from 'aws-amplify-react'; // or 'aws-amplify-react-native';
import { Auth } from 'aws-amplify'
import React, { useEffect, useState } from 'react';
import './App.css';
import hello, { createClient } from './api/hello'
import { get } from 'lodash'

function App() {
  const [client, setClient] = useState({})
  useEffect(() => {
    async function init() {
      const authData = await Auth.currentCredentials() 
      const data = get(authData, 'data.Credentials')
      if (data) {
        setClient({
          lambda: createClient({ ...data }) 
        })
      }
    }
    init()
  },[])
  async function makeRequest() {
    if (client.lambda) {
      const data = await hello(client.lambda)
      alert(JSON.stringify(data))
    } else {
      alert("No client present!")
    }
  }
  return (
    <div>
      <h1>Welcome to Ticketstore</h1>
      <button onClick={() => Auth.signOut()}>LOGOUT</button>
      <button onClick={makeRequest}>Make Request</button>
    </div>
  );
}

export default withAuthenticator(App);
