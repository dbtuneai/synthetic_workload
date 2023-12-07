import os
import time
import argparse
import subprocess
import sys


LOG_PATH = "/var/log/postgresql/postgresql-14-main.log"
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
    if benchmark == "chbenchmark":
        benchmark_command = ["java", "-jar", "benchbase.jar", "-b", f"tpcc,{benchmark}", "-c", f"config/postgres/sample_{benchmark}_config.xml", commands, "-s", "5"]
        subprocess.run(benchmark_command)
    else:
        benchmark_command = ["java", "-jar", "benchbase.jar", "-b", benchmark, "-c", f"config/postgres/sample_{benchmark}_config.xml", commands, "-s", "5"]
        subprocess.run(benchmark_command)


if __name__ == "__main__":
    try:
        wait_for_postgres_ready_for_connect()
        bench("--create=true)
        bench("--load=true")
    except KeyboardInterrupt:
        sys.exit(0)
