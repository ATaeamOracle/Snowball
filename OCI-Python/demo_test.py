import oci
import os.path
import sys
import shapes

import time
# Set up config
#config = oci.config.from_file("~/.oci/config","DEFAULT")
# Create a service client
#identity = oci.identity.IdentityClient(config)
# coding: utf-8
# Copyright (c) 2016, 2018, Oracle and/or its affiliates. All rights reserved.

# Default config file and profile
config = oci.config.from_file("~/.oci/config","DEFAULT")
compute_client = oci.core.ComputeClient(config)
compartment_id = 'ocid1.tenancy.oc1..aaaaaaaayqrveavxbu5ydsobx5aity4oy5lwjlr4kvsuza2kf2sgyd6prnha'
availability_domain = 'uTNr:US-ASHBURN-AD-2'
second_availability_domain = 'uTNr:US-ASHBURN-AD-1'

def get_instance(self, instance_id, **kwargs):
    resource_path = "/instances/{instanceId}"
    method = "GET"

    expected_kwargs = ["retry_strategy"]
    extra_kwargs = [key for key in six.iterkeys(kwargs) if key not in expected_kwargs]
    if extra_kwargs:
        raise ValueError(
            "get_instance got unknown kwargs: {!r}".format(extra_kwargs))

    path_params = {
        "instanceId": instance_id
    }

    path_params = {k: v for (k, v) in six.iteritems(path_params) if v is not missing}

    for (k, v) in six.iteritems(path_params):
        if v is None or (isinstance(v, six.string_types) and len(v.strip()) == 0):
            raise ValueError('Parameter {} cannot be None, whitespace or empty string'.format(k))

    header_params = {
        "accept": "application/json",
        "content-type": "application/json"
    }

    if kwargs.get('retry_strategy'):
        return kwargs['retry_strategy'].make_retrying_call(
            self.base_client.call_api,
            resource_path=resource_path,
            method=method,
            path_params=path_params,
            header_params=header_params,
            response_type="Instance")
    else:
        return self.base_client.call_api(
            resource_path=resource_path,
            method=method,
            path_params=path_params,
            header_params=header_params,
            response_type="Instance")

