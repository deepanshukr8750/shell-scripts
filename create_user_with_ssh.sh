#!/bin/bash

# Function to create a new user account
create_user() {
    local username=$1
    local password=$2

    # Create the user account
    sudo useradd -m -s /bin/bash "$username"

    # Set the user's password
    echo "$username:$password" | sudo chpasswd

    # Add the user to the sudo group (optional, adjust as needed)
    sudo usermod -aG sudo "$username"

    # Create SSH directory and authorized keys file
    sudo mkdir -p "/home/$username/.ssh"
    sudo touch "/home/$username/.ssh/authorized_keys"

    # Set permissions for the SSH directory and authorized keys file
    sudo chmod 700 "/home/$username/.ssh"
    sudo chmod 600 "/home/$username/.ssh/authorized_keys"

    # Set the owner of the SSH directory and authorized keys file
    sudo chown -R "$username:$username" "/home/$username/.ssh"

    echo "User account '$username' has been created."
}

# Usage: create_user_with_ssh <username> <password> <public_key_file>
create_user_with_ssh() {
    local username=$1
    local password=$2
    local public_key_file=$3

    # Create the user account
    create_user "$username" "$password"

    # Add the public key to the authorized keys file
    sudo cat "$public_key_file" | sudo tee -a "/home/$username/.ssh/authorized_keys" > /dev/null

    echo "SSH access has been set up for user '$username'."
}

# Usage example: create_user_with_ssh "newuser" "password" "/path/to/public_key.pub"
create_user_with_ssh "newuser" "password" "/path/to/public_key.pub"
    