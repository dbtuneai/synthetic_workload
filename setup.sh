#Mount data directory
sudo mkdir /mnt/data
sudo mkfs -t ext4 /dev/$VAR || { echo 'Unable to mount disk' ; exit 1; }
sudo mount -t ext4 /dev/$VAR /mnt/data || { echo 'Unable to mount disk' ; exit 1; }

#Install ubuntu packages
sudo apt update
sudo apt -y upgrade
sudo apt-get -y install python3-pip python-dev openjdk-17-jre-headless
sudo rm /usr/bin/python
sudo ln -s /usr/bin/python3.8 /usr/bin/python

#Install PostgreSQL:
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
sudo apt update
sudo apt -y install postgresql-14
sudo apt -y install postgresql-client-14

# Setup Benchbase
cd
git clone --depth 1 https://github.com/cmu-db/benchbase.git
cd benchbase
./mvnw clean package -P postgres
cd target && tar xvzf benchbase-postgres.tgz
mv benchbase-postgres ../..
cd ../..
rm -rf benchbase

mv -v synthetic_workload/benchbase_config_files/* benchbase-postgres/config/postgres/
mv -v synthetic_workload/loader.py benchbase-postgres/
mv -v synthetic_workload/runner.py benchbase-postgres/

# Copy the data from the old directory to the mounted one.
sudo -i -u postgres psql -c "CREATE USER admin WITH LOGIN SUPERUSER PASSWORD 'password';"
sudo rsync -av /var/lib/postgresql /mnt/data
sudo bash -c 'echo "data_directory = '\''/mnt/data/postgresql/14/main'\''" >> /etc/postgresql/14/main/conf.d/initial.conf'
sudo bash -c 'echo "max_connections = 450" >> /etc/postgresql/14/main/conf.d/initial.conf'
sudo bash -c 'echo "max_pred_locks_per_transaction = 500" >> /etc/postgresql/14/main/conf.d/initial.conf'   # Necessary for the Twitter benchmark to run at all
sudo service postgresql restart

#Setup postgres:
sudo chmod -R ugo+rw /mnt/data/
sudo chmod -R 0750 /mnt/data/postgresql/

sudo -u postgres psql -c "CREATE DATABASE benchbase;"