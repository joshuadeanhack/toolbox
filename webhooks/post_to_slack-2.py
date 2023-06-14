#!/usr/bin/env python3
#Environment requires: pip3 install requests p4python

import os
import sys
import requests
from P4 import P4, P4Exception

# Set the Slack API endpoint URL
SLACK_URL = 'https://slack.com/api/chat.postMessage'

# Set the Slack app token and channel
SLACK_TOKEN = 'xobo-TOKEN-GOES-HERE'
SLACK_CHANNEL = '#channel-name'
SWARM_URL = 'https://swarm.example.com'

# Set P4 Connection Variables
P4_PORT = 'ssl:localhost:1666'
P4_USER = 'automation'

def create_p4_instance():
    p4 = P4()
    p4.port = P4_PORT
    p4.user = P4_USER
    return p4

def get_changelist(p4, changelist):
    try:
        p4.connect()
        cl = p4.run_describe('-s', str(changelist))[0]
        p4.disconnect()
        return cl
    except P4Exception as e:
        print("Slack Trigger Script: \nEither connection to perforce, or failed to describe changelist")
        print(e)
        sys.exit(1)

def construct_message(cl, changelist):
    message = f'New changelist submitted by <{SWARM_URL}/users/{cl["user"]}|{cl["user"]}>: '
    message += f'<{SWARM_URL}/changes/{changelist}|{changelist}>\n'
    message += f'Description: {cl["desc"]}\n'
    message += 'Files:\n'
    for f in cl['depotFile'][:2]:
        message += f'- <{SWARM_URL}/files/{f}?change={changelist}|{f}>\n'
    return message

def post_to_slack(message):
    headers = {
        'Content-type': 'application/json',
        'Authorization': f'Bearer {SLACK_TOKEN}'
    }

    data = {
        'channel': SLACK_CHANNEL,
        'text': message
    }

    try:
        response = requests.post(SLACK_URL, headers=headers, json=data)
        if response.status_code != 200:
            print(f"Failed to post message to Slack: {response.content}")
        else:
            print('Message successfully sent to Slack')
        sys.exit(0)
    except Exception as e:
        print("Slack Trigger Script: \nSending a slack notification failed,")
        print(e)
        sys.exit(1)


changelist = sys.argv[1]
p4 = create_p4_instance()
cl = get_changelist(p4, changelist)
message = construct_message(cl, changelist)
post_to_slack(message)
