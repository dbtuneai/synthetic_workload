if [[ -z "${PGVERSION}" ]]; then
  export PGVERSION="16"
fi

if [[ -z "${VAR}" ]]; then
  echo "Please set the disk name in the VAR environment variable"
  exit 1
fi

# Install ubuntu packages
sudo apt update
sudo apt -y upgrade
sudo apt-get -y install python3-pip python3-venv python3-psycopg2 python3-psutil libpq-dev openjdk-21-jre-headless
# sudo pip3 install --upgrade pip
# sudo pip3 install psutil psycopg2

# Install PostgreSQL:
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" | sudo tee  /etc/apt/sources.list.d/pgdg.list
sudo apt update
sudo -E apt -y install postgresql-$PGVERSION
sudo -E apt -y install postgresql-client-$PGVERSION

# Setup Benchbase
cd
git clone https://github.com/cmu-db/benchbase.git
cd benchbase
./mvnw clean package -P postgres -Dmaven.test.skip=true
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
sudo -E bash -c 'echo "data_directory = '\''/mnt/data/postgresql/$PGVERSION/main'\''" >> "/etc/postgresql/${PGVERSION}/main/conf.d/initial.conf"'
sudo -E bash -c 'echo "max_connections = 450" >> "/etc/postgresql/$PGVERSION/main/conf.d/initial.conf"'
sudo -E bash -c 'echo "max_pred_locks_per_transaction = 500" >> "/etc/postgresql/$PGVERSION/main/conf.d/initial.conf"'   # Necessary for the Twitter benchmark to run at all
sudo -E bash -c 'echo "shared_preload_libraries = '\''pg_stat_statements'\''" >> "/etc/postgresql/$PGVERSION/main/conf.d/initial.conf"' #Necessary for tuning for query_runtime

# Mount data directory (the directory will be mounted until you stop your cloud instance, in which case you need to rerun all the commands below)
sudo mkdir /mnt/data
sudo mkfs -t ext4 /dev/$VAR || { echo 'Unable to mount disk' ; exit 1; }
sudo mount -t ext4 /dev/$VAR /mnt/data || { echo 'Unable to mount disk' ; exit 1; }
sudo rsync -av /var/lib/postgresql /mnt/data
sudo chmod -R 750 /mnt/data/postgresql
sudo chown -R postgres:postgres /mnt/data/postgresql
sudo service postgresql restart
