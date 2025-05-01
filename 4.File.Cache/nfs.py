#!/usr/bin/python3

import gc
import time
import subprocess

from prometheus_client import Gauge, Counter, start_http_server

current_cookies = Gauge("current_cookies", "Current number of cookies (inodes) in cache")
current_volumes = Gauge("current_volumes", "Current number of volume cookies (volumes) in cache")
current_vol_col = Counter("current_vol_col", "Number of volume index key collisions in cache")
current_vol_oom = Counter("current_vol_oom", "Number of out of memory events when allocating volume cookies")
acquire_cookies = Counter("acquire_cookies", "Current number of cookies acquired for files")
acquire_successful = Counter("acquire_successful", "Number of successful attempts to acquire cookies for files")
acquire_oom = Counter("aquire_oom", "Number of attempts to acquire cookies that failed due to out of memory")
lru_current = Gauge("lru_current", "Current number of cookies in the LRU cache")
lru_expired = Counter("lru_expired", "Number of cookies that have been processed (expired) in the LRU cache")
lru_removed = Counter("lru_removed", "Number of cookies that have been removed from the LRU cache")
lru_dropped = Counter("lru_dropped", "Number of cookies that have been relinquished or withdrawn from the LRU cache")
lru_cull = Gauge("lru_cull", "Time (in jiffies) until the next culling (processing) of the LRU cache")
inval_cookies = Counter("inval_cookies", "Number of cookies invalidated (removed) from the cache")
update_cookies = Counter("update_cookies", "Number of update cookies sent to cache")
resize_requests = Counter("resize_requests", "Number of resize requests")
resize_skips = Counter("resize_skips", "Number of skipped resize requests")
relinquish_cookies = Counter("relinquish_cookies", "Number of relinquish cookie requests")
relinquish_retires = Counter("relinquish_retires", "Number of relinquish requests where retire=true")
relinquish_drops = Counter("relinquish_drops", "Number of cookies no longer blocking reacquisition")
nospace_writes = Counter("nospace_writes", "Number of failed cache writes due to no space in cache")
nospace_creates = Counter("nospace_creates", "Number of failed cache creates due to no space in cache")
nospace_cull = Counter("nospace_cull", "Number of objects culled to make space when no space occurs")
io_reads = Counter("io_reads", "Number of read operations by the cache")
io_writes = Counter("io_writes", "Number of write operations by the cache")

# get_stats() function
#
# Process the lines of /proc/fs/fscache/stats to get the metrics data.  As each line is different,
# we're going to use the first column to differentiate, since it has the type.
#
# In the case of counters, because we want to use rate and irate, and because the .inc method
# adds the current value to the previous one (not preferred) rather than setting the new value (preferred),
# we are going to use the private method ._value.set instead. With this in mind, counter values must either be
# zero or positive. A negative will reset the counter, breaking graphing.  The counter should only reset when
# the process does.  There is another option, using Gauges, but that makes rate calculations harder and it doesn't
# allow for irate calculations.  Information is in the Stack Overflow conversation below:
#
# https://stackoverflow.com/questions/47929310/how-update-counter-set-new-value-after-avery-request-not-increment-new-value-t

def get_stats():
    cache_stats = []
    results = subprocess.run(["cat /proc/fs/fscache/stats"], stdout=subprocess.PIPE, text=True, shell=True)
    for line in (results.stdout.splitlines()):
        cache_stats.append(line.replace(":", "").split())
    for line in (cache_stats):
        if (line[0] == "Cookies"):
            current_cookies.set(line[1].split("=")[1])
            current_volumes.set(line[2].split("=")[1])
            current_vol_col._value.set(int(line[3].split("=")[1]))
            current_vol_oom._value.set(int(line[4].split("=")[1]))
        if (line[0] == "Acquire"):
            acquire_cookies._value.set(int(line[1].split("=")[1]))
            acquire_successful._value.set(int(line[2].split("=")[1]))
            acquire_oom._value.set(int(line[3].split("=")[1]))
        if (line[0] == "LRU"):
            lru_current.set(line[1].split("=")[1])
            lru_expired._value.set(int(line[2].split("=")[1]))
            lru_removed._value.set(int(line[3].split("=")[1]))
            lru_dropped._value.set(int(line[4].split("=")[1]))
            lru_cull.set(line[5].split("=")[1])
        if (line[0] == "Invals"):
            inval_cookies._value.set(int(line[1].split("=")[1]))
        if (line[0] == "Updates"):
            update_cookies._value.set(int(line[1].split("=")[1]))
            resize_requests._value.set(int(line[2].split("=")[1]))
            resize_skips._value.set(int(line[3].split("=")[1]))
        if (line[0] == "Relinqs"):
            relinquish_cookies._value.set(int(line[1].split("=")[1]))
            relinquish_retires._value.set(int(line[2].split("=")[1]))
            relinquish_drops._value.set(int(line[3].split("=")[1]))
        if (line[0] == "NoSpace"):
            nospace_writes._value.set(int(line[1].split("=")[1]))
            nospace_creates._value.set(int(line[2].split("=")[1]))
            nospace_cull._value.set(int(line[3].split("=")[1]))
        if (line[0] == "IO"):
            io_reads._value.set(int(line[1].split("=")[1]))
            io_writes._value.set(int(line[2].split("=")[1]))

if __name__ == "__main__":

    start_http_server(${metricsCustomStatsPort})
    while True:
        get_stats()
        gc.collect()
        time.sleep(${metricsIntervalSeconds})
