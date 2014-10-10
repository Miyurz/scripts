# Vagrant Environment Variables file

# These variables are used in two ways:
#  - During Vagrant creation and provisioning
#  - Sourced by .bash_profile for use by the application inside the Vagrant VM

# DO NOT change these values directly unless it is a permanent change.
# If you need to override them temporarily, create file env.local.sh in ../local/

# App configuration
export PGUSER=keylocationsg
export PGPASSWORD=devpg
export PGPORT=5432
export PGHOST=127.0.0.1

export VAGRANT_PG_HOST_PORT=5433
export VAGRANT_MEMORY=1024
export VAGRANT_CPUS=1

export OTP_PORT=8080

git config --global core.editor nano
git config --global color.ui true

# Windows hosts can't support symlinks
export NPM_CONFIG_BIN_LINKS=false
export NPM_CONFIG_FETCH_RETRIES=5

# Display git branch name and colours on command prompt
function parse_git_branch {
    git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1) /'
}
PS1="\[\e[32m\]\$(parse_git_branch)\[\e[33m\]\h:\w \$ \[\e[m\]"
export PS1
