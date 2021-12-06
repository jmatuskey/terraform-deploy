
# Description
TODO

# Recovery 

Because the lambda that shuts down the hub modifies both the ASGs associated with the EKS nodegroups, and the nodegroups themselves, it is necessary to manually reset the min/max/desired values of those ASGs and nodegroups.

```
# Reset autoscaling groups
awsu aws autoscaling update-auto-scaling-group --auto-scaling-group-name <CORE-ASG-NAME> --min-size 3 --max-size 4 --desired-capacity 3
awsu aws autoscaling update-auto-scaling-group --auto-scaling-group-name <NOTEBOOK-ASG-NAME> --min-size 1 --max-size 80 --desired-capacity 2

# Reset EKS nodegroups
awsu aws eks update-nodegroup-config --cluster-name <DEPLOYMENT> --nodegroup-name <CORE-NODEGROUP-NAME> --scaling-config minSize=3,maxSize=4,desiredSize=3
awsu aws eks update-nodegroup-config --cluster-name <DEPLOYMENT> --nodegroup-name <NOTEBOOK-NODEGROUP-NAME> --scaling-config minSize=1,maxSize=80,desiredSize=3
```
