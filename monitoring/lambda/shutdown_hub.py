import os
import time
import boto3
from botocore.exceptions import ClientError

def send_emails(sns_client, cluster_name, account_id, efs_id, recipient_adrs):
    subject = f'**ALERT** {cluster_name} EFS exceeded size limit, shutting down...'
    message = f'EFS for {cluster_name} has exceeded the size limit, shutting down the hub...}'

    topic = sns_client.create_topic(
        Name=f'EFS-exeeded-size-limit-{cluster_name}'
    )

    for adr in recipient_adrs.split():
        sns_client.subscribe(
            TopicArn=topic.arn,
            Protocol='email',
            Endpoint=adr,
         )

        sns_client.publish(
            TopicArn=topic.arn,
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
    recipient_adr= os.environ.get('RECIPIENT_EMAILS')

    eks_client = boto3.client('eks')
    asg_client = boto3.client('autoscaling')
    sns_client = boto3.client('sns', region_name='us-east-1', verify=False)

    return_code = 0
    try:
        nodegroups = get_nodegroups(eks_client, cluster_name)
        for group in nodegroups:
            asg = get_nodegroup_asg(eks_client, cluster_name, group)
            update_asg(asg_client, asg)

        send_emails(sns_client, cluster_name, account_id, efs_id, recipient_adrs)
    except:
        return_code = 1

    return {
        'statusCode': 200,
        'body': f'return code: {str(return_code)}'
    }
