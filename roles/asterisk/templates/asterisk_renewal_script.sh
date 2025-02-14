#!/bin/bash

# All variables
# Directory where asterisk stores the certificate, certificate will be $asterisk_certs_dir/asterisk.crt
asterisk_certs_dir=/etc/asterisk/certs
caddy_certs_dir=/var/lib/caddy/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/
# Asterisk DNS name that should be renewed
asterisk_domain={{ item }}
# Minimum expiration renewal, if more do nothing
expiration_threshold_seconds=1296000 # 15 days

# ----------- Beginning ----------------
echo "Starting asterisk cert updater"

# Get the expiration of the asterisk certificate
expiration_date_ast=$(date --date="$(openssl x509 -enddate -noout -in "$asterisk_certs_dir/asterisk.crt"|cut -d= -f 2)" +%s)
# Add the nft rule 
rule_number=$(nft  -e -a add rule inet filter input tcp dport { 80, 443 } accept | awk '/.* .* { 80, 443 } .* # handle [0-9]+/ {print $NF}')
echo "Creating rule handle $rule_number listen on all ports 80,443 created"

# exit condition for while loop
are_cert_ok=0
# While certificate doesn't exit or expired in less than $expiration_threshold_seconds
# Wait 1 min for caddy to renew the certificate
while [ $are_cert_ok == 0 ]
do
	# Check if folder exists if not wait
	if [ -f "$caddy_certs_dir/$asterisk_domain/$asterisk_domain.crt" ]; then
		# Check caddy asterisk expiration date
		expiration_date_caddy=$(date --date="$(openssl x509 -enddate -noout -in "$caddy_certs_dir/$asterisk_domain/$asterisk_domain.crt"|cut -d= -f 2)" +%s)
		# If expiration date is more than $expiration_threshold_seconds then wait for renew
		current_epoch_seconds=$(date +%s)
		expiration_day_caddy_cert=$((current_epoch_seconds - expiration_date_caddy))
		if [ "$expiration_day_caddy_cert" -gt "$expiration_threshold_seconds" ]; then
			echo Cert is due to expire on $(date --date=$expiration_date_caddy), waiting for renewal
			systemctl restart caddy
			sleep 1m	
		else
			# Check if certificate caddy and asterisk are the same
			# if not update the certificates and exits
			if [ ! "$expiration_date_ast" -eq "$expiration_date_caddy" ]; then   
				echo Updating asterisk certificate
				cp $caddy_certs_dir/$asterisk_domain/$asterisk_domain.crt $asterisk_certs_dir/asterisk.crt 
				cp $caddy_certs_dir/$asterisk_domain/$asterisk_domain.key $asterisk_certs_dir/asterisk.key
				export are_cert_ok=1
				echo Cert is renewed and expires on $(date --date=@$expiration_date_caddy), exiting
			
			fi
			echo Cert is up2date and expires on $(date --date=@$expiration_date_caddy), exiting
			export are_cert_ok=1
		fi
	else
		echo Certificate for domain $asterisk_domain doesn\'t exist, waiting
		systemctl restart caddy
		sleep 1m
	fi
done
echo Cleaning nft port 80, 443 rule $rule_number
nft delete rule inet filter input handle $rule_number
