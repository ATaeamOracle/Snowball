# Copyright (c) 2016, 2017, Oracle and/or its affiliates. All rights reserved.
# Author : Michel Benoliel
# Start or stop a set of compute instances with a give name prefix.
# could be enhanced with tagging once tags are supported in the Python SDK

import sys
from fnmatch import fnmatch, fnmatchcase
import oci
from oci.config import from_file
from oci.core import ComputeClient

def printUsage():
	print "usage: instances -action prefix"
	print "i.e. instances -START Linux-DS"
	print "i.e. instances -STOP Linux-DS"
	print "i.e. instances -LIST *"
	exit()

if len(sys.argv) != 3:
	printUsage()


action = sys.argv[1].upper()
instancePrefix = sys.argv[2]

print action
if action != "-START" and action != "-STOP"  and action !="-LIST":
	printUsage
	
config = from_file()

compute  =  ComputeClient(config)
instances =[]
state = "RUNNING"
checkpoint_compartment="ocid1.compartment.oc1..aaaaaaaaowoexmvnos6b7e6csjshxkim4nu2fhte3cyttyp6cg5alwmf4csq"
frontline_compartment = "ocid1.tenancy.oc1..aaaaaaaago6llvabe46trovlahpyfeakbovwbogudjprbts3gxwstplxtyxq"
# response = compute.list_instances(compartment_id=frontline_compartment)
response = compute.list_instances(compartment_id=checkpoint_compartment)
for instance in response.data:
	if fnmatch(instance.display_name, instancePrefix):
		if action == "-LIST" :
			print instance.display_name.ljust(32) + "	" + instance.lifecycle_state
			print instance
		if action == "-STOP" and instance.lifecycle_state == "RUNNING":
			print "stopping  instance" ,instance.display_name
			state = "STOPPED"
			instances.append(instance)
			stopResponse = compute.instance_action(instance.id, 'stop')
		if action == "-START" and instance.lifecycle_state == "STOPPED":
			print "starting instance " ,instance.display_name
			state = "RUNNING"
			instances.append(instance)
			stopResponse = compute.instance_action(instance.id, 'start')

			
# wait for START/STOP to complete
if action == "-STOP" or action == "-START":
	for instance in instances:
		get_stop_response = oci.wait_until(compute, compute.get_instance(instance.id), 'lifecycle_state', state)
		print "instance ", instance.display_name.lpad(32),  state
			
