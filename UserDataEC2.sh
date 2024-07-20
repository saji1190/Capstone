#! /bin/bash -eux
# # Install updates
sudo yum update -y

# Configure AWS CLI with IAM role credentials
aws configure set default.region us-west-2

#Enable EPEL Repository and Install stress-ng
sudo amazon-linux-extras install epel
sudo yum install -y stress-ng

#Install httpd
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd

#Install mysql
#sudo yum install -y mysql
sudo amazon-linux-extras install mariadb10.5
sudo systemctl start mariadb
sudo systemctl enable mariadb


#Install PHP
#sudo yum install -y php
sudo amazon-linux-extras enable php7.4
sudo amazon-linux-extras install 


# Update all installed 
sudo yum update -y

#Restart Apache
sudo systemctl restart httpd

#Install Wordpress
DBRootPassword='rootpassword'
mysqladmin -u root password $DBRootPassword

# Retrieve RDS endpoint from Terraform output
DBName="dbresume90"
DBUser="dbuser90"
DBPassword="qwerty123"
RDS_ENDPOINT="localhost"
Documentroot="/var/www/html"

# Create a temporary file to store the database value
# sudo touch db.txt
# sudo chmod 777 db.txt
# sudo echo "DATABASE $DBName;" >> db.txt
# sudo echo "USER $DBUser;" >> db.txt
# sudo echo "PASSWORD $DBPassword;" >> db.txt
# sudo echo "HOST $RDS_ENDPOINT;" >> db.txt

#Create Wordpress database

sudo echo "CREATE DATABASE $DBName;" >> /tmp/db.setup 
sudo echo "CREATE USER '$DBUser'@'localhost' IDENTIFIED BY '$DBPassword';" >> /tmp/db.setup 
sudo echo "GRANT ALL ON $DBName.* TO '$DBUser'@'localhost';" >> /tmp/db.setup 
sudo echo "FLUSH PRIVILEGES;" >> /tmp/db.setup 
sudo mysql -u root --password=$DBRootPassword < /tmp/db.setup
sudo rm /tmp/db.setup

sudo yum install -y wget
sudo wget http://wordpress.org/latest.tar.gz -P $Documentroot

cd $Documentroot
sudo tar -zxvf latest.tar.gz
sudo cp -rvf wordpress/* .

sudo rm -R wordpress
sudo rm latest.tar.gz

echo "Terraform output:"

# Copy wp-config.php file to wordpress directory
sudo cp ./wp-config-sample.php ./wp-config.php
sudo sed -i "s/'database_name_here'/'$DBName'/g" wp-config.php
sudo sed -i "s/'username_here'/'$DBUser'/g" wp-config.php
sudo sed -i "s/'password_here'/'$DBPassword'/g" wp-config.php
sudo sed -i "s/'localhost'/'$RDS_ENDPOINT'/g" wp-config.php
sudo echo "define('FS_METHOD', 'direct');" >> /var/www/html/wp-config.php

#Grant permissions

sudo usermod -a -G apache ec2-user 
sudo chown -R ec2-user:apache /var/www 
sudo chmod 2775 /var/www 
sudo find /var/www -type d -exec chmod 2775 {} \; 
sudo find /var/www -type f -exec chmod 0664 {} \; 

sudo mysql -h "$RDS_ENDPOINT" -u "$DBUser" -p"$DBPassword" "$DBName" -e "SHOW DATABASES;"

#Install PHP Extensions
sudo amazon-linux-extras enable php7.4
sudo yum clean metadata
sudo yum install -y php-cli php-pdo php-fpm php-json php-mysqlnd

# Restart Apache
sudo systemctl restart httpd
sudo systemctl start mariadb


# Create credentials and config files of sandbox and set ownership and permissions
sudo mkdir /home/ec2-user/.aws
sudo touch /home/ec2-user/.aws/credentials /home/ec2-user/.aws/config
sudo chmod 600 /home/ec2-user/.aws/credentials /home/ec2-user/.aws/config
sudo chmod 755 /home/ec2-user/.aws
sudo chown ec2-user:ec2-user /home/ec2-user/.aws -R

# Configure AWS credentials
sudo echo "[default]" > /home/ec2-user/.aws/credentials
sudo echo "aws_access_key_id=${access_key}" >> /home/ec2-user/.aws/credentials
sudo echo "aws_secret_access_key=${secret_key}" >> /home/ec2-user/.aws/credentials
sudo echo "aws_session_token=${session_token}" >> /home/ec2-user/.aws/credentials

# Configure AWS config
sudo echo "[default]" > /home/ec2-user/.aws/config
sudo echo "output = json" >> /home/ec2-user/.aws/config
sudo echo "region = ${region}" >> /home/ec2-user/.aws/config

# # Variables
# S3_BUCKET="saji-worpress24"
# HTML_FILE="html.zip"
# DB_FILE="dbresume90_14-24.sql"
# DOWNLOAD_DIR="/tmp"
# WEB_DIR="/var/www"

# Step 1: Download files from S3
#echo "Downloading $HTML_FILE from S3..."
sudo -u ec2-user aws s3 sync s3://saji-worpress24/ /var/www

# Step 2: Extract HTML files to /var/www
#echo "Extracting $HTML_FILE to $WEB_DIR..."
sudo mv /var/www/html /var/www/html.bak
sudo unzip -o /var/www/html.zip -d /var/www

# Step 3: Restore the database
#echo "Restoring database from $DB_FILE..."
sudo mysql dbresume90 < /var/www/dbresume90_14-24.sql

# Fetch the new IP address
 NEW_URL=$(curl -s http://checkip.amazonaws.com)
 
 # Fetch the old URL from the database
OldURL=$(sudo mysql $DBName -Ns -e "SELECT CONCAT('http://', SUBSTRING_INDEX(SUBSTRING_INDEX(option_value, '/', 3), '://', -1)) AS OldURL FROM wp_options WHERE option_name = 'siteurl' OR option_name = 'home' LIMIT 1;")


# Update URLs in the database
#echo "Updating WordPress database URLs from $OldURL to $NEW_URL..."

mysql -u $DBUser -p$DBPassword -h $RDS_ENDPOINT $DBName <<EOF
UPDATE wp_options SET option_value = replace(option_value, '$OldURL', 'http://$NEW_URL') WHERE option_name = 'home' OR option_name = 'siteurl';
UPDATE wp_posts SET guid = replace(guid, '$OldURL','http://$NEW_URL');
UPDATE wp_posts SET post_content = replace(post_content, '$OldURL', 'http://$NEW_URL');
UPDATE wp_postmeta SET meta_value = replace(meta_value,'$OldURL','http://$NEW_URL');
EOF

echo "WordPress database URLs updated successfully."
# change owner of wordpress directory
sudo chown -R apache:apache /var/www/html

sudo systemctl restart httpd
sudo systemctl start mariadb

