gpg --verbose --batch --yes --passphrase ${3} --output /catapult/secrets/configuration.yml --decrypt /catapult/secrets/configuration.yml.gpg
gpg --verbose --batch --yes --passphrase ${3} --output /catapult/secrets/id_rsa --decrypt /catapult/secrets/id_rsa.gpg
gpg --verbose --batch --yes --passphrase ${3} --output /catapult/secrets/id_rsa.pub --decrypt /catapult/secrets/id_rsa.pub.gpg

chmod 700 /catapult/secrets/configuration.yml
chmod 700 /catapult/secrets/id_rsa
chmod 700 /catapult/secrets/id_rsa.pub
