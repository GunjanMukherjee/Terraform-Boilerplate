exports.handler = async (event) => {
    let clientName = process.env.CLIENT_NAME;

    const response = {
        statusCode: 200,
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify('Message from ' + clientName),
    };
    return response;
};