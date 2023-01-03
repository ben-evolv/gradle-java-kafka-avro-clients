#!/bin/bash -e
#
# Snowflake SnowSQL Bash Installer
#
set -o errexit
set -o pipefail

SNOWSQL_COMMENT="# added by Snowflake SnowSQL installer"
SNOWSQL_TMPDIR=$(mktemp -d)
trap "rm -rf $SNOWSQL_TMPDIR" EXIT

function check_dir_writable() {
    local dest=$1
    local touchfile=touchfile
    if ! mkdir -p $dest; then
        echo "[ERROR] Failed to create a directory $dest Ensure $dest can be created."
        exit 1
    fi
    if ! touch $dest/$touchfile; then
        echo "[ERROR] Failed to write a file in $dest Ensure $dest can be writable."
        exit 1
    fi
    rm -f $dest/$touchfile
}

function add_dest_path_to_profile() {
    local dest=$1
    local profile=$2
    echo "Updating $profile to have $dest in PATH"
    cp -p $profile "$profile-snowflake.bak" || true
    echo "
$SNOWSQL_COMMENT
export PATH=$dest:\$PATH" >> $profile
}

function untar_snowsql() {
    local dest=$1
    local is_profile_updated=$2
    sed -e '1,/^exit$/d' "$0" | (cd "$SNOWSQL_TMPDIR" && tar xzf - )
    cp -rp $SNOWSQL_TMPDIR/snowsql $dest
    local zipname=$(basename $(ls "$SNOWSQL_TMPDIR"/*.zip | head -n 1))
    local IFS='-'
    read -ra zipname_parts <<< "$zipname"
    local v=${zipname_parts[1]}
    mkdir -p ~/.snowsql
    (cd ~/.snowsql && rm -rf $v && unzip -q "$SNOWSQL_TMPDIR/$zipname" -d $v && touch $v/ok)
    if [[ "$is_profile_updated" == "true" ]]; then
        echo "Open a new terminal session to make the updated PATH take effect."
    fi
}

function get_started() {
    local dest=$1
    echo "**********************************************************************"
    echo " Congratulations! Follow the steps to connect to Snowflake DB."
    echo "**********************************************************************"
    echo
    echo "1. Open a new terminal window."
    echo "2. Execute the following command to test your connection:"
    echo "      snowsql -a <account_name> -u <login_name>"
    echo
    echo "      Enter your password when prompted. Enter !quit to quit the connection."
    echo
    echo "3. Add your connection information to the ~/.snowsql/config file:"
    echo "      accountname = <account_name>
                username = <login_name>
                password = <password>"
    echo
    echo "4. Execute the following command to connect to Snowflake:"
    echo
    echo "      snowsql"
    echo
    echo "See the Snowflake documentation <https://docs.snowflake.net/manuals/user-guide/snowsql.html> for more information."
}

function add_prelink_config() {
    local dest=$1
    PRELINK_CONF_DIR=/etc/prelink.conf.d
    if [[ "$dest" != "$HOME/bin" ]]; then
        if [[ -e "$PRELINK_CONF_DIR" ]]; then
            echo "Adding prelink config for SnowSQL in $PRELINK_CONF_DIR/snowsql.conf. You may need sudo privilege."
            if ! sudo bash -c "echo '-b snowsql' > $PRELINK_CONF_DIR/snowsql.conf"; then
                echo "Failed to update prelink config of SnowSQL"
            else
                return 0
            fi
        else
            echo "No prelink configuration folder is found: $PRELINK_CONF_DIR."
        fi
        echo "Skipping adding the prelink config for SnowSQL"
        echo "If the system uses prelink, add snowsql to the exclusion list such that prelink won't alter the executable file." 
        echo
        echo "sudo bash -c \"echo '-b snowsql' > /etc/prelink.conf.d/snowsql.conf\""
    fi
}

IS_PROFILE_UPDATED=false

echo "**********************************************************************"
echo " Installing SnowSQL, Snowflake CLI."
echo "**********************************************************************"
echo
if [[ -n "$SNOWSQL_DEST" && -n "$SNOWSQL_LOGIN_SHELL" ]]; then
    if [[ ! -e $SNOWSQL_LOGIN_SHELL ]]; then
        echo "The login shell script doesn't exist: $SNOWSQL_LOGIN_SHELL"
        exit 1
    fi
    if ! grep -q -E "^$SNOWSQL_COMMENT" $SNOWSQL_LOGIN_SHELL; then
        add_dest_path_to_profile $SNOWSQL_DEST $SNOWSQL_LOGIN_SHELL
        IS_PROFILE_UPDATED=true
    fi
    mkdir -p $SNOWSQL_DEST
    untar_snowsql $SNOWSQL_DEST $IS_PROFILE_UPDATED
    get_started $SNOWSQL_DEST
    exit 0
fi

read -p "Specify the directory in which the SnowSQL components will be installed. [~/bin] " SNOWSQL_DEST
if [[ -z "$SNOWSQL_DEST" ]]; then
    SNOWSQL_DEST=~/bin
else
    SNOWSQL_DEST="${SNOWSQL_DEST/#\~/$HOME}"
fi
check_dir_writable "$SNOWSQL_DEST"
check_dir_writable "$HOME/.snowsql"

SNOWSQL_LOGIN_SHELL=
if [[ -e ~/.zprofile ]]; then
    SNOWSQL_LOGIN_SHELL=~/.zprofile
elif [[ -e ~/.zshrc ]]; then
    SNOWSQL_LOGIN_SHELL=~/.zshrc
elif [[ -e ~/.profile ]]; then
    SNOWSQL_LOGIN_SHELL=~/.profile
elif [[ -e ~/.bash_profile ]]; then
    SNOWSQL_LOGIN_SHELL=~/.bash_profile
elif [[ -e ~/.bashrc ]]; then
    SNOWSQL_LOGIN_SHELL=~/.bashrc
fi

if [[ -z "$SNOWSQL_LOGIN_SHELL" ]]; then
    read -p "Do you want to add $SNOWSQL_DEST to PATH in $SNOWSQL_LOGIN_SHELL? [y/N] " YN
    if [[ "$YN" == "y" || "$YN" == "Y" ]]; then
        read -p "Which login shell script do you want to add $SNOWSQL_DEST to PATH? " SNOWSQL_LOGIN_SHELL
        if [[ -z "$SNOWSQL_LOGIN_SHELL" ]]; then
            echo "Aborted."
            exit 2
        fi
        add_dest_path_to_profile $SNOWSQL_DEST $SNOWSQL_LOGIN_SHELL
        IS_PROFILE_UPDATED=true
    fi
else
    if ! grep -q -E "^$SNOWSQL_COMMENT" $SNOWSQL_LOGIN_SHELL; then
        read -p "Do you want to add $SNOWSQL_DEST to PATH in $SNOWSQL_LOGIN_SHELL? [y/N] " YN
        if [[ "$YN" == "y" || "$YN" == "Y" ]]; then
            add_dest_path_to_profile $SNOWSQL_DEST $SNOWSQL_LOGIN_SHELL
            IS_PROFILE_UPDATED=true
        fi
    fi
fi
untar_snowsql $SNOWSQL_DEST $IS_PROFILE_UPDATED
add_prelink_config $SNOWSQL_DEST
get_started $SNOWSQL_DEST
exit