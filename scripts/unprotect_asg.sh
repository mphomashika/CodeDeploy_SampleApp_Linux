#!/bin/bash
#
# Copyright 2014 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
#  http://aws.amazon.com/apache2.0
#
# or in the "license" file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.

. $(dirname $0)/common_functions.sh

msg "Running AWS CLI with region: $(get_instance_region)"

# get this instance's ID
INSTANCE_ID=$(get_instance_id)
if [ $? != 0 -o -z "$INSTANCE_ID" ]; then
    error_exit "Unable to get this instance's ID; cannot continue."
fi

# Get current time
msg "Started $(basename $0) at $(/bin/date "+%F %T")"
start_sec=$(/bin/date +%s.%N)

msg "Checking if instance $INSTANCE_ID is part of an AutoScaling group"
asg=$(autoscaling_group_name $INSTANCE_ID)
if [ $? == 0 -a -n "$asg" ]; then
    msg "Found AutoScaling group for instance $INSTANCE_ID: $asg"
    
    msg "Checking that installed CLI version is at least at version required for AutoScaling Standby and Instance Protection"
    check_cli_version
    if [ $? != 0 ]; then
        error_exit "CLI must be at least version ${MIN_CLI_X}.${MIN_CLI_Y}.${MIN_CLI_Z} to work with AutoScaling Standby"
    fi

    msg "Attempting to put instance into Protected From Scale In"
    autoscaling_set_protected $INSTANCE_ID $asg
    if [ $? != 0 ]; then
        error_exit "Failed to put instance into Protected From Scale In"
    else
        msg "Instance is protected"
        exit 0
    fi
fi

msg "Instance is not part of an ASG, nothing to do."

msg "Finished $(basename $0) at $(/bin/date "+%F %T")"

end_sec=$(/bin/date +%s.%N)
elapsed_seconds=$(echo "$end_sec - $start_sec" | /usr/bin/bc)

msg "Elapsed time: $elapsed_seconds"
