#!/bin/bash

# Configuration
USERNAME="Loki"
SERVERS_FILE="servers.txt"
SSH_KEY="/root/.ssh/mykey.pem"

# Check if servers file exists
if [ ! -f "$SERVERS_FILE" ]; then
    echo "Error: Servers file $SERVERS_FILE not found!"
    exit 1
fi

# Read server list
servers=$(cat "$SERVERS_FILE")

# Authentication type selection
echo "Select authentication method for $USERNAME:"
select auth_type in "Password-based" "Key-based"; do
    case $auth_type in
        "Password-based")
            read -sp "Enter password for $USERNAME: " password
            echo
            ;;
        "Key-based")
            read -p "Enter path to public key file: " pub_key_path
            if [ ! -f "$pub_key_path" ]; then
                echo "Error: Public key file not found!"
                exit 1
            fi
            pub_key=$(cat "$pub_key_path")
            ;;
        *)
            echo "Invalid option"
            exit 1
            ;;
    esac
    break
done

# User creation function
create_remote_user() {
    server=$1
    echo "Processing $server:"

    # Check if user exists
    if ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ec2-user@"$server" "sudo id -u $USERNAME" >/dev/null 2>&1; then
        echo " - User $USERNAME already exists"
    else
        # Create user
        ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ec2-user@"$server" \
        "sudo useradd -m $USERNAME && \
        sudo mkdir -p /home/$USERNAME/.ssh && \
        sudo chmod 700 /home/$USERNAME/.ssh && \
        sudo chown $USERNAME:$USERNAME /home/$USERNAME/.ssh" || { echo " - Failed to create user"; return 1; }

        echo " - User created successfully"
    fi


    # Configure authentication
    case $auth_type in
        "Password-based")
            hashed_pass=$(openssl passwd -1 "$password")
            ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ec2-user@"$server" \
            "echo '$USERNAME:$hashed_pass' | sudo chpasswd -e" || { echo " - Failed to set password"; return 1; }
            ;;



	"Key-based")
    # Copy key to remote server
    scp -o StrictHostKeyChecking=no -i "$SSH_KEY" "$pub_key_path" ec2-user@"$server":/tmp/mykey.pub || { echo " - SCP transfer failed"; return 1; }

    # Configure key authentication
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ec2-user@"$server" \
    "sudo mkdir -p /home/$USERNAME/.ssh && \
    echo \"$pub_key\" | sudo tee /home/$USERNAME/.ssh/authorized_keys > /dev/null && \
    sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh && \
    sudo chmod 700 /home/$USERNAME/.ssh && \
    sudo chmod 600 /home/$USERNAME/.ssh/authorized_keys" || { echo " - Failed to add SSH key"; return 1; }

    # Cleanup temporary file
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ec2-user@"$server" "sudo rm -f /tmp/mykey.pub" || { echo " - Failed to clean up temporary file"; return 1; }
    ;;


    esac

    echo " - Authentication configured successfully"
    return 0
}

# Main execution
for server in $servers; do
    create_remote_user "$server"
done
