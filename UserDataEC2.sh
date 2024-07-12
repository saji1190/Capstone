#! /bin/bash
# # Install updates
sudo yum update -y

# Configure AWS CLI with IAM role credentials
aws configure set default.region us-west-2

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
sudo yum install -y php 
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
sudo wget http://wordpress.org/latest.tar.gz -P /var/www/html/

cd /var/www/html
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