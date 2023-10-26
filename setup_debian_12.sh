# Install ubuntu packages
sudo apt update
sudo apt -y upgrade
sudo apt-get -y install python3-pip git libpq-dev openjdk-17-jre-headless rsync
sudo rm /usr/lib/python3.11/EXTERNALLY-MANAGED
sudo pip3 install --upgrade pip
sudo pip3 install psutil psycopg2

# Install PostgreSQL:
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
sudo apt update
sudo apt -y install postgresql-14
sudo apt -y install postgresql-client-14

# Setup Benchbase
cd
git clone https://github.com/cmu-db/benchbase.git
cd benchbase
git checkout 979b53b043f934220f703b149f27a7ee0f992b63
./mvnw clean package -P postgres
cd target && tar xvzf benchbase-postgres.tgz
mv benchbase-postgres ../..
cd ../..
rm -rf benchbase
mv -v synthetic_workload/benchbase_config_files/* benchbase-postgres/config/postgres/
mv -v synthetic_workload/loader.py benchbase-postgres/
mv -v synthetic_workload/runner.py benchbase-postgres/

# Copy the data from the old directory to the mounted one
sudo -i -u postgres psql -c "CREATE USER admin WITH LOGIN SUPERUSER PASSWORD 'password';"
sudo -i -u postgres psql -c "CREATE DATABASE benchbase;"
sudo bash -c 'echo "data_directory = '\''/mnt/data/postgresql/14/main'\''" >> /etc/postgresql/14/main/conf.d/initial.conf'
sudo bash -c 'echo "max_connections = 450" >> /etc/postgresql/14/main/conf.d/initial.conf'
sudo bash -c 'echo "max_pred_locks_per_transaction = 500" >> /etc/postgresql/14/main/conf.d/initial.conf'   # Necessary for the Twitter benchmark to run at all
sudo bash -c 'echo "shared_preload_libraries = '\''pg_stat_statements'\''" >> /etc/postgresql/14/main/conf.d/initial.conf' #Necessary for tuning for query_runtime

# Mount data directory (the directory will be mounted until you stop your cloud instance, in which case you need to rerun all the commands below)
sudo mkdir /mnt/data
sudo mkfs -t ext4 /dev/$VAR || { echo 'Unable to mount disk' ; exit 1; }
sudo mount -t ext4 /dev/$VAR /mnt/data || { echo 'Unable to mount disk' ; exit 1; }
sudo rsync -av /var/lib/postgresql /mnt/data
sudo chmod -R 750 /mnt/data/postgresql
sudo chown -R postgres:postgres /mnt/data/postgresql
sudo service postgresql restart
