import oci
import sys

config = oci.config.from_file("~/.oci/config","DEFAULT")
compute_client = oci.core.ComputeClient(config)
identity_client = oci.identity.IdentityClient(config)

tenancy_id = config['tenancy']

compartment_id = 'ocid1.tenancy.oc1..aaaaaaaayqrveavxbu5ydsobx5aity4oy5lwjlr4kvsuza2kf2sgyd6prnha'
while not compartment_id:
    compartment_id = input("Please enter your compartment OCID (enter 'list' to list all compartments in your tenancy): ")
    if compartment_id.lower() == 'list':
        compartment_id = None
        try:
            result = oci.pagination.list_call_get_all_results(identity_client.list_compartments, tenancy_id)
            print('All compartments in tenancy: {tenancy_id}'.format(tenancy_id=tenancy_id))
            for compartment in result.data:
                print('\t{name} - {ocid}'.format(name=compartment.name, ocid=compartment.id))
            
            print()
        except oci.exceptions.ServiceError as e:
            print('User does not have permissions to list compartments in this tenancy.')

instances = oci.pagination.list_call_get_all_results(compute_client.list_instances, compartment_id)

if len(instances.data) == 0:
    print("No instances found in compartment id: {compartment_id}".format(compartment_id=compartment_id))
    sys.exit(0)

while True:
    instances_indices_to_act_on = []
    print("Enter a comma separated list of instance(s) you would like to perform an action on using the indices specified below\n")
    instance_index = 0
    for instance in instances.data:
        print('\t[{index}] - {name} - state: {state}'.format(index=instance_index, name=instance.display_name, state=instance.lifecycle_state))
        instance_index += 1

    print()
    instance_list_input = input("(e.g. '0' or '1,2,3'): ")
    instance_indices = [entry.strip() for entry in instance_list_input.split(',')]
    error = False
    for index in instance_indices:
        if len(instances.data) == 1:
            prompt_text = 'The only valid index is 0.'
        else:
            prompt_text = 'Valid indices are between {lower} and {upper} inclusive.'.format(lower=0, upper=len(instances.data)-1)

        try:
            int_index = int(index)
        except ValueError as e:
            print('Instance index is not valid integer: {index}. {text}'.format(index=index, text=prompt_text))
            error = True
            continue
        
        if int_index >= len(instances.data):
            print('Instance index {index} is out of range. {text}'.format(index=index, text=prompt_text))
            error = True
            continue

        instances_indices_to_act_on.append(int_index)

    if not error:
        break


actions = ['start', 'stop', 'softreset', 'reset']
action_prompt = """
    Input the action you would like to perform on the selected instances:

       start - power on

       stop - power off

       softreset - ACPI shutdown and power on

       reset - power off and power on
"""
print(action_prompt)
while True:
    action = input("action: ")
    if action.lower() in actions:
        action = action.lower()
        break

    print('Invalid action. Please enter one of the following: {actions}'.format(actions=", ".join(actions)))

instances_to_act_on = [instances.data[index] for index in instances_indices_to_act_on]
for instance in instances_to_act_on:
    print('Applying action: {action} to instance: {name}...'.format(action=action, name=instance.display_name))
    compute_client.instance_action(instance.id, action)

print('Resulting instance states:')
for instance in instances_to_act_on:
    result = compute_client.get_instance(instance.id).data
    print('Instance: {name}, lifecycle state: {state}'.format(name=result.display_name, state=result.lifecycle_state))
