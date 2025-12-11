#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# SPDX-FileCopyrightText: 2024 Trident IoT, LLC <https://www.tridentiot.com>

USER_ID=${USER_ID:-1000}
GROUP_ID=${GROUP_ID:-1000}
USER_NAME=${USER_NAME:-build}

# Create a group with the specified GID if it doesn't exist
if ! getent group $GROUP_ID >/dev/null; then
    groupadd -g $GROUP_ID $USER_NAME
fi

# Create a user with the specified UID and add to the group if it
# doesn't exist
if ! id -u $USER_NAME >/dev/null 2>&1; then
    useradd -m -u $USER_ID -g $GROUP_ID -s /bin/bash $USER_NAME
fi

# Ensure the home directory is owned by the correct user and group
chown -R $USER_ID:$GROUP_ID /home/$USER_NAME

echo 'ALL ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Run the command as the specified user
exec gosu $USER_NAME "$@"