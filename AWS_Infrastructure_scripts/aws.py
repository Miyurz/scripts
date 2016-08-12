import boto3
import json
import re
import time

boto3.setup_default_session(profile_name='devops')
ec2 = boto3.resource('ec2', region_name='us-east-1')
client = boto3.client('ec2')

def displayAllAMIs():
    response = client.describe_images(
                DryRun=False,
                Owners=[
                            '16813345409345',
                       ],
                Filters=[
                          {
                            'Name': 'name',
                            'Values' : ['simulation*'],
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
    print('Available simulation AMIs are:')
    print '{:40s} {:30s} {:20s}'.format('AMI', 'Creation Date', 'Image ID')
    for i in response['Images']:
        regex='simulation*'
        if re.match(regex, i['Name']) is not None:
           print '{:40s} {:30s} {:20s}'.format(i['Name'], i['CreationDate'], i['ImageId'])
         
def createInstance():
    user_data_script = """#!/bin/bash
                          echo "staging-host" >> /etc/hostname
                          echo "127.0.0.1 staging-host" >>/etc/hosts
                       """
    InstanceId = ec2.create_instances(
                         ImageId='ami-6c75cd7b', 
                         InstanceType='t2.medium', #for testing purpose use t2.medium
                         SubnetId='subnet-d630134d',
                         MinCount=1, 
                         MaxCount=1,
                         UserData=user_data_script
  #                      SecurityGroups=[
  #                                       'string',
  #                                      ],
  #                       SecurityGroupIds=[
  #                                         'string',
  #                                        ] 
  
                       )
    for index,item in enumerate(InstanceId):
        #print index, item.id

        waiter = client.get_waiter('instance_running')
        waiter.config.delay = 2 #custom value for the retry interval because per default it's 15s(too long).
        waiter.config.max_attempts = 20 #(custom value for the max number of attempts, default is too much- 40)
        start = time.time()
        waiter.wait(
            #DryRun=True|False,
            InstanceIds=[
                             item.id,
                        ],
                Filters=[
                         {
                           'Name': 'instance-state-name',
                           'Values': [
                                      'running',
                                     ]
                         }
                         #{
                         #  'Name': 'reason',
                         #  'Values': [
                         #             'string',
                         #            ]
                         #}
                        ]
                #NextToken='string',
                #MaxResults=123
            ) 
        done = time.time()
        elapsed = done - start
        print "It took me %d seconds to bring the node into running state" % elapsed

def showRunningInstances():
    instances = ec2.instances.filter(
        Filters=[
                 {'Name': 'instance-state-name', 'Values': ['running']}
                ]
    )
    print "--------------------------------------------------------------------------------"
    print '{:25s} {:20s} {:20s}'.format('INSTANCE ID     |' ,'INSTANCE TYPE      |','INSTANCE TAG NAME    |')
    print "--------------------------------------------------------------------------------"
    for instance in instances:
        for tagName in instance.tags:
            if tagName['Key'] == 'Name':
                print '{:25s} {:20s} {:20s}'.format(instance.id, instance.instance_type,tagName['Value'])

def terminateInstance():
    print("Terminating instance")

def StopInstance():
    print("Trying to stop instance")

def menu():
    print("1.Display all AMIs")
    print("2.Spin an instance") #Specify AMI Image ID, Subnet ID, Security group, Instance Type, hostname
    print("3.Terminate an instance")
    print("4.Stop an instance")
    print("5.Display running instances")
    try:
       val = int(input("Input your choice"))
    except ValueError:
       print("Input a number") 
    chose(val)

def chose(argument):
    switcher = {
        1: displayAllAMIs,
        2: createInstance,
        3: terminateInstance,
        4: StopInstance,
        5: showRunningInstances,
        6: lambda: "six",
    }
    # Get the function from switcher dictionary
    func = switcher.get(argument, lambda: "nothing")
    return func()

menu()
