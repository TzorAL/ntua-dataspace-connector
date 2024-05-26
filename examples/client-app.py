import requests
import json
from dotenv import load_dotenv
import os

# Load the .env file
load_dotenv()
storage_path = os.environ.get("STORAGE_PATH")
api_key = os.environ.get("API_KEY")
provider_agent_id = os.environ.get("PROVIDER_AGENT_ID")
consumer_agent_id = os.environ.get("CONSUMER_AGENT_ID")
consumer_url = os.environ.get("CONSUMER_URL")
api_version = os.environ.get("API_VERSION")
endpoint = os.environ.get("ENDPOINT")

full_url = f'{consumer_url}/{api_version}/{endpoint}' # https://<baseurl>/<data-app-path>/openapi/<beckend-service-version>/
                                                     
#  agent IDs must contain the full name (connector name + agent id)
headers = {
    'Authorization': 'Bearer' + api_key,  # JWT token
    'Forward-Id': provider_agent_id,         # reciever connector ID
    'Forward-Sender': consumer_agent_id      # Sender connector ID
}

# params used for querying - varies depending on api accessed through the connector
params = {
    "select": "*&and=(timestamp.gte.2018-07-01T00:00:00,timestamp.lte.2018-07-02T00:00:00)",
}

# Sending GET request
response = requests.get(full_url, headers=headers, params=params)

# Check if request was successful (status code 200)
if response.status_code == 200:
    try:
        data = response.json()  # Attempt to decode JSON
        print("Number of entries:", len(data))
        print(json.dumps(data, indent=1))
        for item in data:
            print(json.dumps(item, separators=(',', ':')))
    except ValueError:  # includes simplejson.decoder.JSONDecodeError
        print("Response content is not valid JSON")
        print(response.text)
else:
    print(f"Request failed with status code: {response.status_code}")
    print("Response text:", response.text)
