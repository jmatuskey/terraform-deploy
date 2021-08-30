import boto3
from botocore.exceptions import ClientError

def send_email(ses_client, cluster_name, account_id, efs_id):
    sender = 'no-reply@ses.amazonaws.com'
    recipient = 'cslocum@example.com'

    subject = f'**ALERT** {cluster_name} EFS exceeded size limit, shutting down...'
    html = f"""
        <html>
            <body>
              <h1>f'{cluster_name} EFS exceeded size limit, shutting down the hub...'</h1>
              <p>EFS volume {efs_id} in account {account_id} has exceeded it's size limit.  Immediate attention is required!</p>
            </body>
        </html>
    """

    charset = 'UTF-8'
    try:
        response = client.send_email(
            Destination={
                'ToAddresses': [
                    recipient,
                ],
            },
            Message={
                'Body': {
                    'Html': {
                        'Charset': charset,
                        'Data': html,
                    },
                },
                'Subject': {
                    'Charset': charset,
                    'Data': subject,
                },
            },
            Source=sender,
        )
    except ClientError as e:
        print(e.response['Error']['Message'])

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

    eks_client = boto3.client('eks')
    asg_client = boto3.client('autoscaling')
    ses_client = boto3.client('ses', region_name='us-east-1')

    return_code = 0
    try:
        nodegroups = get_nodegroups(eks_client, cluster_name)
        for group in nodegroups:
            asg = get_nodegroup_asg(eks_client, cluster_name, group)
            update_asg(asg_client, asg)

        send_email(ses_client, cluster_name, account_id, efs_id)
    except:
        return_code = 1

    return {
        'statusCode': 200,
        'body': f'return code: {str(return_code)}'
    }
