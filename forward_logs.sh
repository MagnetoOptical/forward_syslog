#!/bin/bash

# Step 1: Check if rsyslog is installed
if dpkg -l | grep rsyslog; then
    echo "rsyslog is already installed. Skipping to step 5."
    goto_step5=true
else
    # Step 2: Update APT repo
    sudo apt-get update
    
    # Step 3: Check if rsyslog is in the repo and install if present
    if apt-cache show rsyslog > /dev/null 2>&1; then
        sudo apt-get install -y rsyslog
        goto_step5=true
    # Step 4: Check if syslog-ng is in the repo and install if present
    elif apt-cache show syslog-ng > /dev/null 2>&1; then
        sudo apt-get install -y syslog-ng
        goto_step5=false
    else
        echo "Neither rsyslog nor syslog-ng is available in the repository."
        exit 1
    fi
fi

# Step 5: Configure rsyslog if installed
if [ "$goto_step5" = true ]; then
    echo "*.* @|resolvable_hostname_or_ip|:514" | sudo tee -a /etc/rsyslog.conf
    sudo invoke-rc.d rsyslog restart
else
    # Step 6: Configure syslog-ng if installed
    echo "destination d_remote { udp(\"|resolvable_hostname_or_ip|\" port(514)); };" | sudo tee -a /etc/syslog-ng/syslog-ng.conf
    echo "log { source(s_local); destination(d_remote); };" | sudo tee -a /etc/syslog-ng/syslog-ng.conf
    sudo invoke-rc.d syslog-ng restart
fi

# Step 7: Configure any secondary or dependent services (if required)
# Add specific commands here as needed

# Step 8: Start or restart services
if [ "$goto_step5" = true ]; then
    sudo invoke-rc.d rsyslog restart
else
    sudo invoke-rc.d syslog-ng restart
fi

echo "Configuration completed successfully."
