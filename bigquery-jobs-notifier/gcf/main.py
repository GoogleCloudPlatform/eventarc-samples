# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import json
import os

from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail

to_emails = os.environ.get('TO_EMAILS')
sendgrid_api_key = os.environ.get('SENDGRID_API_KEY')

def handle_audit_log(cloud_event):

    # Parse the event body
    aboveLimit, message = read_event_data(cloud_event)

    if aboveLimit:
        notify(message)

    return 'OK', 200

# See event_data.json for the format
def read_event_data(cloud_event):

    # Assume custom event by default
    event_data = cloud_event.data

    protoPayload = event_data['protoPayload']
    principalEmail = protoPayload['authenticationInfo']['principalEmail']
    job = protoPayload['serviceData']['jobCompletedEvent']['job']
    jobId = job['jobName']['jobId']
    jobStatistics = job['jobStatistics']
    createTime = jobStatistics['createTime']
    totalBilledBytes = 0
    if 'totalBilledBytes' in jobStatistics:
        totalBilledBytes = float(jobStatistics['totalBilledBytes'])
    query = job['jobConfiguration']['query']['query']
    aboveLimit = totalBilledBytes > 1000000000

    message = f"""
The following BigQuery job completed

principalEmail: {principalEmail}
jobId: {jobId}
createTime: {createTime}
query: {query}
totalBilledBytes: {totalBilledBytes}, above 1GB? {aboveLimit}"""

    print(message)

    return aboveLimit, message


def notify(message):

    if to_emails is None or sendgrid_api_key is None:
        print("Email notification skipped as TO_EMAILS or SENDGRID_API_KEY is not set")
        return

    print(f"Sending email to {to_emails}")

    message = Mail(
        from_email='noreply@bigquery-usage-notifier.com',
        to_emails=to_emails,
        subject='An expensive BigQuery job just completed',
        html_content=f'<html><pre>{message}</pre></html>')
    try:
        print(f"Email content {message}")
        sg = SendGridAPIClient(sendgrid_api_key)
        response = sg.send(message)
        print(f"Email status code {response.status_code}")
    except Exception as e:
        print(e)