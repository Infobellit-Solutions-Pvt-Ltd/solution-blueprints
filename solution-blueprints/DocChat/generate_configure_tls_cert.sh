cat > /tmp/airm-nipio-openssl.cnf <<'CNF'
[req]
default_bits = 2048
prompt = no
default_md = sha256
x509_extensions = v3_req
distinguished_name = dn
[dn]
CN = *.45.63.79.40.nip.io
[v3_req]
subjectAltName = @alt_names
[alt_names]
DNS.1 = *.45.63.79.40.nip.io
DNS.2 = 45.63.79.40.nip.io
CNF

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /tmp/cluster-tls.key \
  -out /tmp/cluster-tls.crt \
  -config /tmp/airm-nipio-openssl.cnf


kubectl -n kgateway-system create secret tls cluster-tls \
  --cert=/tmp/cluster-tls.crt \
  --key=/tmp/cluster-tls.key

