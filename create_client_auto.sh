#!/bin/bash
export OPTION="1"
export CLIENT=$1
echo $1
client=$1
CLIENT=$1

echo $client

if grep -qs "14.04" /etc/os-release; then
	echo "Ubuntu 14.04 is too old and not supported"
	exit
fi

if grep -qs "jessie" /etc/os-release; then
	echo "Debian 8 is too old and not supported"
	exit
fi

if grep -qs "CentOS release 6" /etc/redhat-release; then
	echo "CentOS 6 is too old and not supported"
	exit
fi

if grep -qs "Ubuntu 16.04" /etc/os-release; then
	echo 'Ubuntu 16.04 is no longer supported in the current version of openvpn-install
Use an older version if Ubuntu 16.04 support is needed: https://git.io/vpn1604'
	exit
fi

# Detect Debian users running the script with "sh" instead of bash
if readlink /proc/$$/exe | grep -q "dash"; then
	echo "This script needs to be run with bash, not sh"
	exit
fi

if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, you need to run this as root"
	exit
fi

if [[ ! -e /dev/net/tun ]]; then
	echo "The TUN device is not available
You need to enable TUN before running this script"
	exit
fi

if ! iptables -t nat -nL &>/dev/null; then
	echo "Unable to initialize the iptables/netfilter NAT table, setup can't continue.
If you are a LowEndSpirit customer, see here: https://git.io/nfLES
If you are getting this message on any other provider, ask them for support."
	exit
fi

if [[ -e /etc/debian_version ]]; then
	os="debian"
	group_name="nogroup"
elif [[ -e /etc/centos-release || -e /etc/redhat-release ]]; then
	os="centos"
	group_name="nobody"
else
	echo "Looks like you aren't running this installer on Debian, Ubuntu or CentOS"
	exit
fi

new_client () {
	# Generates the custom client.ovpn
	{
	cat /etc/openvpn/server/client-common.txt
	echo "<ca>"
	cat /etc/openvpn/server/easy-rsa/pki/ca.crt
	echo "</ca>"
	echo "<cert>"
	sed -ne '/BEGIN CERTIFICATE/,$ p' /etc/openvpn/server/easy-rsa/pki/issued/"$1".crt
	echo "</cert>"
	echo "<key>"
	cat /etc/openvpn/server/easy-rsa/pki/private/"$1".key
	echo "</key>"
	echo "<tls-crypt>"
	sed -ne '/BEGIN OpenVPN Static key/,$ p' /etc/openvpn/server/tc.key
	echo "</tls-crypt>"
	} > ~/"$1".ovpn
}



	echo "Looks like OpenVPN is already installed."
	client=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g' <<< "$unsanitized_client")
			while [[ -z "$1" || -e /etc/openvpn/server/easy-rsa/pki/issued/"$1".crt ]]; do
				echo "$1: invalid client name."
				read -p "Client name: " unsanitized_client
				client=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g' <<< "$unsanitized_client")
			done
			cd /etc/openvpn/server/easy-rsa/
			EASYRSA_CERT_EXPIRE=3650 ./easyrsa build-client-full "$1" nopass
			# Generates the custom client.ovpn
			new_client "$1"
			echo
			echo "Client $1 added, configuration is available at:" ~/"$1.ovpn"
			exit