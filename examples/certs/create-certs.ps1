
# create CA
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:prime256v1 -out ca.key
openssl req -new -sha256 -key ca.key -subj "/CN=Test CA" -out ca.csr
openssl x509 -req -days 700 -in ca.csr -signkey ca.key -out ca.crt
openssl x509 -in ca.crt -text -noout

# create server 
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:prime256v1 -out server.key
openssl req -new -sha256 -key server.key -out server.csr -subj "/CN=Test Server Cert/"

@"
[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = localhost
IP.1 = 127.0.0.1
"@  -replace "`r","" | out-file ext.txt -encoding ascii -NoNewline
openssl x509 -req -days 700 -in server.csr -CA ca.crt -CAkey ca.key -out server.crt -CAcreateserial -extensions v3_req -extfile ext.txt


# create pfx
openssl pkcs12 -export -out identity.pfx -inkey server.key -in server.crt -certfile ca.crt  -passout pass:hunter2 -nodes
# openssl pkcs12 -export -out identity.pfx -inkey server.key -in server.crt -certfile .\ca.crt -nodes -passout pass:

# Make sure the .crt and key file have the same name and the key file has extension .key
# certutil -mergepfx MySite.cert MySite.pfx


openssl pkcs12 -in identity.pfx -passin pass:hunter2 -nodes
