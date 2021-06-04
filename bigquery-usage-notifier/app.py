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
import logging
import os

from flask import Flask, request
from cloudevents.http import from_http

from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail

to_emails = os.environ.get('TO_EMAILS')
sendgrid_api_key = os.environ.get('SENDGRID_API_KEY')

app = Flask(__name__)

@app.route('/', methods=['POST'])
def handle_post():
    #app.logger.info(pretty_print_POST(request))

    # Read the CloudEvent from the request
    cloud_event = from_http(request.headers, request.get_data())

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

    app.logger.info(message)

    return aboveLimit, message


def notify(message):

    if to_emails is None or sendgrid_api_key is None:
        app.logger.info("Email notification skipped as TO_EMAILS or SENDGRID_API_KEY is not set")
        return

    app.logger.info(f"Sending email to {to_emails}")

    message = Mail(
        from_email='noreply@bigquery-usage-notifier.com',
        to_emails=to_emails,
        subject='An expensive BigQuery job just completed',
        html_content=f'<html><pre>{message}</pre></html>')
    try:
        app.logger.info(f"Email content {message}")
        sg = SendGridAPIClient(sendgrid_api_key)
        response = sg.send(message)
        app.logger.info(f"Email status code {response.status_code}")
    except Exception as e:
        print(e)

def pretty_print_POST(req):
    return '{}\r\n{}\r\n\r\n{}'.format(
        req.method + ' ' + req.url,
        '\r\n'.join('{}: {}'.format(k, v) for k, v in req.headers.items()),
        req.data,
    )

if __name__ != '__main__':
    # Redirect Flask logs to Gunicorn logs
    gunicorn_logger = logging.getLogger('gunicorn.error')
    app.logger.handlers = gunicorn_logger.handlers
    app.logger.setLevel(gunicorn_logger.level)
    app.logger.info('Service started...')
else:
    app.run(debug=True, host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
