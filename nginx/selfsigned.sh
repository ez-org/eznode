# -- expected to be `source`ed

: ${SELFSIGNED_KEYSIZE:=2048}
: ${SELFSIGNED_DAYS:=365}

if [ -f /data/nginx-ssl/selfsigned.key ]; then
  debug ssl Using self-signed certificate in /data/nginx-ssl
else
  info ssl Generating RSA-$SELFSIGNED_KEYSIZE key and a self-signed certificate to /data/nginx-ssl
  mkdir -p /data/nginx-ssl
  openssl req -x509 -nodes -subj '/' \
    -days $SELFSIGNED_DAYS -newkey rsa:$SELFSIGNED_KEYSIZE \
    -keyout /data/nginx-ssl/selfsigned.key -out /data/nginx-ssl/selfsigned.crt \
    > /dev/null 2>&1 || error nginx Key generation failed
fi
