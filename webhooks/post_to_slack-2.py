#!/usr/bin/env python3
#Envrionment requires: pip3 install requests p4python
import sys
import requests
from P4 import P4, P4Exception


def get_changelist_details(changelist, perforce):
    """Get the details of a Perforce changelist.

    Args:
        changelist (int): The changelist number
        perforce (p4): The Perforce Object
    Returns:
        dict: The changelist details
    Raises:
        P4Exception: If an error occurs while connecting to Perforce.
    """
    perforce.connect()
    cl = p4.run_describe('-s', str(changelist))[0]
    perforce.disconnect()
    return cl


def construct_slack_message(cl_details, changelist, SWARM_URL):
    """Construct a message to post in Slack.

    Args:
        cl_details (dict): The changelist details
        changelist: Changelist number
        SWARM_URL: Weblink to the swarm interface
    Returns:
        str: The Slack message.
    """
    message = f'New changelist submitted by <{SWARM_URL}/users/{cl_details["user"]}|{cl_details["user"]}>: '
    message += f'<{SWARM_URL}/changes/{changelist}|{changelist}>\n'
    message += f'Description: {cl_details["desc"]}\n'
    message += 'Files:\n'
    for f in cl_details['depotFile'][:2]:
        message += f'- <{SWARM_URL}/files/{f}?change={changelist}|{f}>\n'
    return message


def post_slack_message(message, slack_url, slack_token, slack_channel):
    """Post a message to Slack.

    Args:
        message (str): The Slack message.
    Raises:
        Exception: If an error occurs while posting the message to Slack.
    """
    headers = {
        'Content-type': 'application/json',
        'Authorization': f'Bearer {slack_token}'
    }
    data = {
        'channel': slack_channel,
        'text': message
    }
    response = requests.post(slack_url, headers=headers, json=data)
    if response.status_code != 200:
        raise Exception(f"Failed to post message to Slack: {response.content}")


# Set P4
p4 = P4()
p4.port = 'ssl:localhost:1666'
p4.user = 'automation'

# Slack API endpoint URL
SLACK_URL = 'https://slack.com/api/chat.postMessage'
SWARM_URL = 'https://swarm.example.com'

# Setup the Slack app token and channel
SLACK_TOKEN = 'xobo-TOKEN-GOES-HERE'
SLACK_CHANNEL = '#channel-name'

# Get the changelist number from the command line arguments
changelist = sys.argv[1]

# Get the changelist details
changelist_info = get_changelist_details(changelist, p4)

# Construct the Slack message
message = construct_slack_message(changelist_info, changelist, SWARM_URL)

# Post the Slack message
post_slack_message(message, SLACK_URL)

