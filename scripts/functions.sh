#!/bin/bash

function datef() {
    # Output:
    # Sat Jun  8 20:29:08 2019
    date "+%a %b %-d %T %Y"
}

function createConfig() {
        cd "$APP_PERSIST_DIR"
        CLIENT_PATH="$APP_PERSIST_DIR/clients/$1"
        CONTENT_TYPE=application/text
        FILE_PATH="$CLIENT_PATH/$1"
        BASE_CONFIG="$APP_INSTALL_PATH/config/client.ovpn"

        # Redirect stderr to the black hole
        /usr/share/easy-rsa/easyrsa build-client-full "$1" nopass &> /dev/null
        # Writing new private key to '/usr/share/easy-rsa/pki/private/client.key
        # Client sertificate /usr/share/easy-rsa/pki/issued/client.crt
        # CA is by the path /usr/share/easy-rsa/pki/ca.crt

        mkdir -p $CLIENT_PATH

        cp "pki/private/$1.key" "pki/issued/$1.crt" pki/ca.crt /etc/openvpn/ta.key $CLIENT_PATH

        # Set default value to HOST_ADDR if it was not set from environment
        if [ -z "$HOST_ADDR" ]
        then
                HOST_ADDR='localhost'
        fi

        # Embed client authentication files into config file
        cat ${BASE_CONFIG} \
                "$CLIENT_PATH/ca.crt" <(echo -e '</ca>\n<cert>') \
                "$CLIENT_PATH/$1.crt" <(echo -e '</cert>\n<key>') \
                "$CLIENT_PATH/$1.key" <(echo -e '</key>\n<tls-auth>') \
                "$CLIENT_PATH/ta.key" <(echo -e '</tls-auth>') \
                >> "$CLIENT_PATH/$1.ovpn"

        echo "$(datef) $FILE_PATH file has been generated"

        echo "$(datef) Config server started, download your $1 config at http://$HOST_ADDR/"
        echo "$(datef) NOTE: After you download your client config, http server will be shut down!"

        { echo -ne "HTTP/1.1 200 OK\r\nContent-Length: $(wc -c <$FILE_PATH.ovpn)\r\nContent-Type: $CONTENT_TYPE\r\nContent-Disposition: attachment; fileName=\"$1.ovpn\"\r\nAccept-Ranges: bytes\r\n\r\n"; cat "$FILE_PATH.ovpn"; } | nc -w0 -l 8080

        echo "$(datef) Config http server has been shut down"

}