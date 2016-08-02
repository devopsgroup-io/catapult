source "/catapult/provisioners/redhat/modules/catapult.sh"


# remove directories from /var/www/repositories/apache/ that no longer exist in configuration
# create an array of domains
while IFS='' read -r -d '' key; do
    domain_environment=$(echo "$key" | grep -w "domain" | cut -d ":" -f 2 | tr -d " ")
    if [ "$1" != "production" ]; then
        domain_environment=$1.$domain_environment
    fi
    array_domain_environment+=("${domain_environment}")
    array_conf_domain_environment+=("${domain_environment}.conf")
    array_htpasswd_domain_environment+=("${domain_environment}.htpasswd")
done < <(echo "${configuration}" | shyaml get-values-0 websites.apache)

# cleanup /var/log/httpd/${domain}/ directories
for directory in /var/log/httpd/*/; do
    # when there are no matches, for defaults to the match /var/log/httpd/*/, ignore this result
    # on a new provision, there will be no log directories
    if [ -e "$directory" ]; then
        folder_domain_environment=$(basename $directory)
        if ! [[ "${array_domain_environment[*]}" =~ "${folder_domain_environment}" ]]; then
            echo -e "\t * cleaning up /var/log/httpd/${folder_domain_environment}/ as the website has been removed for your configuration..."
            sudo chmod 0777 -R $directory
            sudo rm -rf $directory
        fi
    fi
done
# cleanup /etc/httpd/sites-enabled/*.htpasswd files
for file in /etc/httpd/sites-enabled/*.htpasswd; do
    # when there are no matches, for defaults to the match /etc/httpd/sites-enabled/*.htpasswd, ignore this result
    # there may not be a .htpasswd
    if [ -e "$file" ]; then
        file_domain_environment=$(basename $file)
        if ! [[ "${array_htpasswd_domain_environment[*]}" =~ "${file_domain_environment}" ]]; then
            echo -e "\t * cleaning up /etc/httpd/sites-enabled/${file_domain_environment} as the website has been removed for your configuration..."
            sudo chmod 0777 -R $file
            sudo rm -f $file
        fi
    fi
done
# cleanup /etc/httpd/sites-enabled/*.conf files
for file in /etc/httpd/sites-enabled/*.conf; do
    # when there are no matches, for defaults to the match /etc/httpd/sites-enabled/*.conf, ignore this result
    # on a new provision, the .conf files do not exist yet
    if [ -e "$file" ]; then
        file_domain_environment=$(basename $file)
        if ! ([[ "${array_conf_domain_environment[*]}" =~ "${file_domain_environment}" ]] || [ "_default_.conf" == "${file_domain_environment}" ]); then
            echo -e "\t * cleaning up /etc/httpd/sites-enabled/${file_domain_environment} as the website has been removed for your configuration..."
            sudo chmod 0777 -R $file
            sudo rm -f $file
        fi
    fi
done
# cleanup /etc/httpd/sites-available/*.conf files
for file in /etc/httpd/sites-available/*.conf; do
    # when there are no matches, for defaults to the match /etc/httpd/sites-available/*.conf, ignore this result
    # on a new provision, the .conf files do not exist yet
    if [ -e "$file" ]; then
        file_domain_environment=$(basename $file)
        if ! [[ "${array_conf_domain_environment[*]}" =~ "${file_domain_environment}" ]]; then
            echo -e "\t * cleaning up /etc/httpd/sites-available/${file_domain_environment} as the website has been removed for your configuration.."
            sudo chmod 0777 -R $file
            sudo rm -f $file
        fi
    fi
done

# reload apache
sudo systemctl reload httpd.service
sudo systemctl status httpd.service
