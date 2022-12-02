import os
import time
import argparse

LOG_PATH = "/var/log/postgresql/postgresql-14-main.log"
RESTORE_DATA_DIR = "/mnt/data/rsync"
DATA_DIR = "/mnt/data/postgresql"
parser = argparse.ArgumentParser()
parser.add_argument("--benchmark", help="Select a benchmark from epinions, chbenchmark and resourcestresser.", default="resourcestresser")
args = parser.parse_args()
benchmark = args.benchmark


def get_connect():
    command = "pg_isready"
    output = os.popen(command).read()
    return "accepting connections" in output


def wait_for_postgres_ready_for_connect():
    print("Waiting for connect...", end='', flush=True)
    while not get_connect():
        print('.', end='', flush=True)
        time.sleep(1)
    print('.')


def bench(commands):
    if bench == "chbenchmark":
        os.system("java -jar benchbase.jar -b tpcc, {} -c config/postgres/sample_{}_config.xml {} -s 5".format(benchmark,benchmark,commands))
    else:
        os.system("java -jar benchbase.jar -b {} -c config/postgres/sample_{}_config.xml {} -s 5".format(benchmark,benchmark,commands))


if __name__ == "__main__":
    while True:
        wait_for_postgres_ready_for_connect()
        bench("--execute=true")
