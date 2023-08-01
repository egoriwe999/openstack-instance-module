#cloud-config
runcmd:
  # Commented out as already present in the image
  # - apt-get update
  # - apt-get install -y curl openssl
  # Follows https://docs.docker.com/engine/security/https/
  - DOCKER_DAEMON_IP="$(curl --ipv4 -skL http://icanhazip.com)"
  - DOCKER_CERT_DIR_SRV=/etc/docker
  - DOCKER_CERT_DIR_CLIENT=/root/.docker
  # Server certs
  - mkdir -p "$${DOCKER_CERT_DIR_SRV}"
  - openssl genrsa -aes256 -out "$${DOCKER_CERT_DIR_SRV}/ca-key.pem" -passout "pass:${password}" 4096
  - echo "[req]\ndefault_bits = 4096\nprompt = no\ndefault_md = sha256\ndistinguished_name=dn" > "$${DOCKER_CERT_DIR_SRV}/openssl-srv.cnf"
  - echo "[dn]\nC=${country}\nST=${state}\nL=${locality}\nO=${organization}\nOU=DevOps" >> "$${DOCKER_CERT_DIR_SRV}/openssl-srv.cnf"
  - echo "emailAddress=${email}\nCN = ${domain}" >> "$${DOCKER_CERT_DIR_SRV}/openssl-srv.cnf"
  - openssl req -passin "pass:${password}" -new -x509 -days 3650 -key "$${DOCKER_CERT_DIR_SRV}/ca-key.pem" -sha256 -out "$${DOCKER_CERT_DIR_SRV}/ca.pem" -config "$${DOCKER_CERT_DIR_SRV}/openssl-srv.cnf"
  - openssl genrsa -passout "pass:${password}" -out "$${DOCKER_CERT_DIR_SRV}/server-key.pem" 4096
  - openssl req -passin "pass:${password}" -subj "/CN=${domain}" -sha256 -new -key "$${DOCKER_CERT_DIR_SRV}/server-key.pem" -out "$${DOCKER_CERT_DIR_SRV}/server.csr"
  - echo "subjectAltName = DNS:${domain},IP:$${DOCKER_DAEMON_IP},IP:127.0.0.1" > "$${DOCKER_CERT_DIR_SRV}/openssl-srv-extfile.cnf"
  - echo "extendedKeyUsage = serverAuth" >> "$${DOCKER_CERT_DIR_SRV}/openssl-srv-extfile.cnf"
  - openssl x509 -passin "pass:${password}" -req -days 3650 -sha256 -in "$${DOCKER_CERT_DIR_SRV}/server.csr" -CA "$${DOCKER_CERT_DIR_SRV}/ca.pem" -CAkey "$${DOCKER_CERT_DIR_SRV}/ca-key.pem" -CAcreateserial -out "$${DOCKER_CERT_DIR_SRV}/server-cert.pem" -extfile "$${DOCKER_CERT_DIR_SRV}/openssl-srv-extfile.cnf"
  # Client auth
  - mkdir -p "$${DOCKER_CERT_DIR_CLIENT}"
  - openssl genrsa -out "$${DOCKER_CERT_DIR_CLIENT}/key.pem" -passout "pass:${password}" 4096
  - openssl req -passin "pass:${password}" -subj '/CN=client' -new -key "$${DOCKER_CERT_DIR_CLIENT}/key.pem" -out "$${DOCKER_CERT_DIR_CLIENT}/client.csr"
  - echo "extendedKeyUsage = clientAuth" > "$${DOCKER_CERT_DIR_CLIENT}/openssl-client-extfile.cnf"
  - openssl x509 -passin "pass:${password}" -req -days 3650 -sha256 -in "$${DOCKER_CERT_DIR_CLIENT}/client.csr" -CA "$${DOCKER_CERT_DIR_SRV}/ca.pem" -CAkey "$${DOCKER_CERT_DIR_SRV}/ca-key.pem" -CAcreateserial -out "$${DOCKER_CERT_DIR_CLIENT}/cert.pem" -extfile "$${DOCKER_CERT_DIR_CLIENT}/openssl-client-extfile.cnf"
  - chmod -v 0400 "$${DOCKER_CERT_DIR_SRV}/ca-key.pem" "$${DOCKER_CERT_DIR_SRV}/server-key.pem"
  - cp "$${DOCKER_CERT_DIR_SRV}/ca.pem" "$${DOCKER_CERT_DIR_CLIENT}"
  # Add SystemD drop-in to customize Docker Engine flags
  - mkdir -p /etc/systemd/system/docker.service.d
  - echo "[Service]\nExecStart=\nExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --tlsverify --tlscacert=$${DOCKER_CERT_DIR_SRV}/ca.pem --tlscert=$${DOCKER_CERT_DIR_SRV}/server-cert.pem --tlskey=$${DOCKER_CERT_DIR_SRV}/server-key.pem -H=0.0.0.0:2376" > /etc/systemd/system/docker.service.d/10-expose-api-tls.conf
  # Apply the changes
  - systemctl daemon-reload
  - systemctl restart docker
  - docker restart traefik # or it loses connection to Docker socket
