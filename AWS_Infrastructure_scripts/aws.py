import boto3
import json
import re

boto3.setup_default_session(profile_name='devops')
ec2 = boto3.resource('ec2', region_name='us-east-1')
client = boto3.client('ec2')
#ec2.create_instances(ImageId='ami-6c75cd7b', InstanceType='m4.4xlarge',SubnetId='subnet-d6301eeb',MinCount=1, MaxCount=1)

def choseAMI():
    response = client.describe_images(
                DryRun=False,
                Owners=[
                            '1111111111',
                       ],
                Filters=[
                          {
                            'Name': 'name',
                            'Values' : ['org-simulation*'],
                            'Name': 'is-public',
                            'Values': [
                                        'False',
                                      ],
                            'Name': 'state',
                            'Values': [
                                       'available',
                                      ]
                          },
                        ]
                                 )

     #print response
    print('Available org-simulation AMIs are:')
    print '{:40s} {:30s} {:20s}'.format('AMI', 'Creation Date', 'Image ID')
    for i in response['Images']:
        regex='kapital-simulation*'
        if re.match(regex, i['Name']) is not None:
           print '{:40s} {:30s} {:20s}'.format(i['Name'], i['CreationDate'], i['ImageId'])

#def choseInstanceType():
         
def createInstance():
    InstanceId = ec2.create_instances(
                         ImageId='ami-6c75cf45', 
                         #InstanceType='m4.4xlarge',
                         InstanceType='t2.medium', #for testing purpose use t2.medium
                         SubnetId='subnet-23m7sbs',
                         MinCount=1, 
                         MaxCount=1
  #                      SecurityGroups=[
  #                                       'string',
  #                                      ],
  #                       SecurityGroupIds=[
  #                                         'string',
  #                                        ] 
  
                       )
    print len(InstanceId)
    for index,item in enumerate(InstanceId):
        print index, item.id
    #[ec2.Instance(id='i-31f060c9')] 
    #[ec2.Instance(id='i-f4f2620c'), ec2.Instance(id='i-f7f2620f')]

        waiter = client.get_waiter('instance_running')
        waiter.wait(
#                DryRun=True|False,
                InstanceIds=[
                             item.id,
                            ],
                Filters=[
                         {
                           'Name': 'instance-state-name',
                           'Values': [
                                      'string',
                                     ]
                         },
                         {
                           'Name': 'reason',
                           'Values': [
                                      'string',
                                     ]
                         }
                        ]
                #NextToken='string',
                #MaxResults=123
                ) 

#choseAMI()
#choseInstanceType()
createInstance()
#terminateInstance()
#haltInstance()
