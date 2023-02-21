#!/usr/bin/env python3
#Envrionment requires: pip3 install requests p4python

import os
import sys
import requests
from P4 import P4, P4Exception

# Get the changelist number from the command line arguments
changelist = sys.argv[1]

# Define the Slack API endpoint URL
slack_url = 'https://slack.com/api/chat.postMessage'

# Set the Slack app token and channel
SLACK_TOKEN = 'xobo-TOKEN-GOES-HERE'
SLACK_CHANNEL = '#channel-name'
SWARM_URL = 'https://swarm.example.com'

# Set P4 Connection Variables
P4_PORT = 'ssl:localhost:1666'
P4_USER = 'automation'
#P4_PASSWORD = '' #Not needed as machine has login ticket for automation already

# Create a new P4 instance
p4 = P4()
p4.port = P4_PORT
p4.user = P4_USER
#p4.password = P4_PASSWORD

try:
    # Connect to the Perforce server
    p4.connect()

    # Get the changelist details
    cl = p4.run_describe('-s', str(changelist))[0]

    # Disconnect from the Perforce server
    p4.disconnect()

    # Construct the message to post in Slack
    message = f'New changelist submitted by <{SWARM_URL}/users/{cl["user"]}|{cl["user"]}>: '
    message += f'<{SWARM_URL}/changes/{changelist}|{changelist}>\n'
    message += f'Description: {cl["desc"]}\n'
    message += 'Files:\n'
    for f in cl['depotFile'][:2]:
        message += f'- <{SWARM_URL}/files/{f}?change={changelist}|{f}>\n'

    # Set the headers for the Slack API request
    headers = {
        'Content-type': 'application/json',
        'Authorization': f'Bearer {SLACK_TOKEN}'
    }

    # Set the data for the Slack API request
    data = {
        'channel': SLACK_CHANNEL,
        'text': message
    }

    # Post request the message to Slack using the Slack API
    response = requests.post(slack_url, headers=headers, json=data)

    # Check the response from the Slack API
    if response.status_code != 200:
        print(f"Failed to post message to Slack: {response.content}")
    else:
        print('Message successfully sent to Slack')
    sys.exit(0)

except P4Exception as e:
    print("Slack Trigger Script: \nEither connection to perforce, or failed to describe changelist")
    print(e)
    sys.exit(1)

except Exception as e:
    print("Slack Trigger Script: \nSending a slack notification failed,")
    print(e)
    sys.exit(1)
