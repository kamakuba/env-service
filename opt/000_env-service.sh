#!/usr/bin/env bash

localPort="1092"
privateKey="$HOME/.ssh/heroku_exec_rsa"

authorized_keys=$(cat << EOF | base64 -d
c3NoLXJzYSBBQUFBQjNOemFDMXljMkVBQUFBREFRQUJBQUFCQVFEZGdUaVNBVFM1T2ZCYVhXMGJm
ZG9nYlhtckVUZ2JGd2lmdWJSaGJIQlF4Z2NIaGgxR2x1RW53TTlPMkVscEU0M2picnVscnExR0Zl
SkNERE1HNzJqQXEyR1VTNnNPVTBZYXBSRE56b0hJR25NZUtheTJIZnExWVp4eVRWanY5U084YzRT
OGw3MHRPeFFKY2puZ0Q5ZzlyV3BxcU5Sa21BT2dKUElpK2ZIcUJ3eVRSMWkzRzVqa1F3alM0aWpt
YjhTcnJHamorSWtZOHFQUi8xS29jL2d3RlY4SWVrRkJCMTNwblAzTE01SjFVWkZ5MEREdVQ3OC9J
N0x6MlNaRVRyaFBveVJoUDBVMjd2c1lSQUg3aG9PNExILzQ4ZEJycXhWdURySmkwYkNlZW91bHVs
dS9sWlNDb2hGamtpOTl0MUdqRHpOWU4xb1FLWjcyUjU0WmNGYmggCg==
EOF
)

log_error() {
  echo "[Env-Service] ERROR: ${1}"
}

log_info() {
  echo "[Env-Service] ${1}"
}

if [ -z "$(ps -C sshd -o pid=)" ]; then
	mkdir -p $(dirname $privateKey)
	ssh-keygen -f ${privateKey} -t rsa -N '' -C '' > /dev/null 2>&1
	echo $authorized_keys > $HOME/.ssh/authorized_keys

	cat << EOF > $HOME/.ssh/sshd_config
HostKey ${privateKey}
AuthorizedKeysFile $HOME/.ssh/authorized_keys
UsePrivilegeSeparation no
TCPKeepAlive yes
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

	log_info "Starting env-service..."
	/usr/sbin/sshd -f $HOME/.ssh/sshd_config -o "Port ${localPort}"
	if [ $? -ne 0 ]; then
		log_error "Could not start env-service!"
	else
		log_info "env-service started successfully"
	fi
else
	grep -q $authorized_keys $HOME/.ssh/authorized_keys > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo $authorized_keys >> $HOME/.ssh/authorized_keys
		log_error "env-service keys updated"
	else
		log_info "env-service is already running"
	fi
fi

mkdir -p $HOME/web-data/$(whoami)
