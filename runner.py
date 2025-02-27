"""
This file is a wrapper for the benchbase benchmark runner.
It runs the benchmarks with some custom java configurations
and restarts the benchmark if it finishes.
"""

import os
import time
import argparse
import subprocess
import sys

parser = argparse.ArgumentParser()
parser.add_argument(
    "--benchmark",
    help="Select a benchmark from epinions, tpch and resourcestresser.",
    default="resourcestresser"
)
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
    java_args = [
        "-Xmx10g",  # Maximum heap size
        "-XX:+UseG1GC",  # Use the Garbage-First (G1) Garbage Collector
        "-XX:G1HeapRegionSize=4M",  # Set G1 heap region size
        "-XX:MaxGCPauseMillis=200",  # Set maximum GC pause time
        "-XX:ParallelGCThreads=4",  # Set number of parallel GC threads
        "-XX:+HeapDumpOnOutOfMemoryError",  # Enable heap dump on OOM error
        "-XX:HeapDumpPath=/tmp/heapdump"  # Specify heap dump path
    ]

    benchmark_command = [
        "java",
        *java_args,
        "-jar",
        "benchbase.jar",
        "-b",
        benchmark,
        "-c",
        f"config/postgres/sample_{benchmark}_config.xml",
        commands,
        "-s",
        "5"
    ]

    subprocess.run(benchmark_command)


if __name__ == "__main__":
    try:
        while True:
            wait_for_postgres_ready_for_connect()
            print("Starting benchmark...")
            bench("--execute=true")
    except KeyboardInterrupt:
        sys.exit(0)
