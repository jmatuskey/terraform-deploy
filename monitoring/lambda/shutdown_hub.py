import boto3


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
    cluster = 'roman'

    eks_client = boto3.client('eks')
    asg_client = boto3.client('autoscaling')

    return_code = 0
    try:
        nodegroups = get_nodegroups(eks_client, cluster)
        for group in nodegroups:
            asg = get_nodegroup_asg(eks_client, cluster, group)
            update_asg(asg_client, asg)
    except:
        return_code = 1

    return {
        'statusCode': 200,
        'body': f'return code: {str(return_code)}'
    }
