import os
import time
import copy
import boto3
from botocore.exceptions import ClientError

def send_emails(sns_client, cluster_name, account_id, efs_id, recipient_adrs):
    subject = f'**ALERT** {cluster_name} EFS exceeded size limit, attempting to shut down'
    message = f"""
EFS {efs_id} for {cluster_name} has exceeded the size limit, attempting to shut down the hub...

Account ID - {account_id}

Take action immediately!
    """
    # create new topic
    topic = sns_client.create_topic(
        Name=f'efs-exeeded-size-limit-{cluster_name}'
    )

    # get existing subscriptions
    response = sns_client.list_subscriptions_by_topic(
        TopicArn=topic['TopicArn']
    )

    # send subscription confirmation emails for new registrants
    new_subscriptions = {}
    for adr in recipient_adrs:
        print(f'for adr: {adr}')
        adr = adr.strip(',')
        new_subscriptions[adr] = {}
        new_subscriptions[adr]["arns"] = []
        new_subscriptions[adr]["sub"] = True

    for s in response['Subscriptions']:
        sub_arn = s['SubscriptionArn']
        email = s['Endpoint'].strip(',')
        if email in recipient_adrs:
            new_subscriptions[email]["arns"].append(sub_arn)

    for email in new_subscriptions:
        for arn in new_subscriptions[email]["arns"]:
            if 'arn:aws:sns' in arn:
                 new_subscriptions[email]["sub"] = False

    for email in new_subscriptions:
        if new_subscriptions[email]["sub"]:
            sns_client.subscribe(
                TopicArn=topic['TopicArn'],
                Protocol='email',
                Endpoint=email
            )

    sns_client.publish(
        TopicArn=topic['TopicArn'],
        Message=message,
        Subject=subject
    )

def get_nodegroups(eks_client, cluster_name):
    response = eks_client.list_nodegroups(clusterName=cluster_name)

    return response['nodegroups']

def get_nodegroup_asg(eks_client, cluster_name, nodegroup):
    response = eks_client.describe_nodegroup(
        clusterName=cluster_name,
        nodegroupName=nodegroup
    )

    return response['nodegroup']['resources']['autoScalingGroups'][0]['name']

def update_asg(asg_client, asg_name):
    asg_client.update_auto_scaling_group(
        AutoScalingGroupName=asg_name,
        MinSize=0,
        MaxSize=0,
        DesiredCapacity=0
    )

def lambda_handler(event, context):
    account_id = os.environ.get('ACCOUNT_ID')
    cluster_name = os.environ.get('CLUSTER_NAME')
    efs_id = os.environ.get('EFS_ID')
    recipient_adrs= os.environ.get('RECIPIENT_EMAILS').split()

    eks_client = boto3.client('eks')
    asg_client = boto3.client('autoscaling')
    sns_client = boto3.client('sns', region_name='us-east-1', verify=False)

    return_code = 0
    try:
        send_emails(sns_client, cluster_name, account_id, efs_id, recipient_adrs)
        nodegroups = get_nodegroups(eks_client, cluster_name)
        for group in nodegroups:
            asg = get_nodegroup_asg(eks_client, cluster_name, group)
            update_asg(asg_client, asg)
    except Exception as e:
        print(e)
        return_code = 1

    return {
        'statusCode': str(return_code),
        'body': f'return code: {str(return_code)}'
    }
