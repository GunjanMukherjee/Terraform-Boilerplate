export const handler = async(event) => {
    console.log('event', event)

    const token = event['authorizationToken']

    console.log('token', token)
    
    
    let permission = "Deny";
    if(token === "my-secret-token") {
    	permission = "Allow"
    }
        
    const authResponse = { 
        "principalId": "abc123", 
        "policyDocument": 
            { 
                "Version": "2012-10-17", 
                "Statement": 
                        [
                            {
                                "Action": "execute-api:Invoke", 
                                "Resource": ["arn:aws:execute-api:ap-south-1:975050159399:5gxbii1pcc/dev/POST/demo-path"], 
                                "Effect": `${permission}`
                            }
                        ]
            }
        
    }
    return authResponse;
};
