import requests
import json

# API endpoint
url = 'https://enershare.epu.ntua.gr/provider-data-app/openapi/0.5/'    # https://<baseurl>/<data-app-path>/openapi/<beckend-service-version>/
endpoint = 'efcomp'                                                     # API endpoint 

jwt_token = 'APIKEY-tfiXkagpufdLKvdyyXxwEMwG' # API key defined in values.yaml file at "is.security.key"

# Headers (if any)
headers = {
    'Authorization': 'Bearer' + jwt_token,
    'Forward-Id': 'urn:ids:enershare:connectors:NTUA:Consumer:ConsumerAgent',         # reciever connector ID
    'Forward-Sender': 'urn:ids:enershare:connectors:NTUA:Provider:ProviderAgent'      # Sender connector ID
}

# Sending GET request
response = requests.get(url+endpoint, headers=headers)

# Check if request was successful (status code 200)
if response.status_code == 200:
    try:
        data = response.json()  # Attempt to decode JSON
        print(json.dumps(data, indent=4))
    except ValueError:  # includes simplejson.decoder.JSONDecodeError
        print("Response content is not valid JSON")
        print(response.text)
else:
    print(f"Request failed with status code: {response.status_code}")
    print("Response text:", response.text)
