#!/usr/bin/env bash
#
# Ivan Angelov ivangotoy@gmail.com
# https://digtvbg.com/
#
# Check some HUGEPAGES counts. To be developed further.

PAGE_COUNT=$(rg trans /proc/vmstat | cut -c 31-)
THP_POOL_SIZE=$(rg AnonH /proc/meminfo | cut -c 18-)

printf "Number of TRANSPARENT HugePages is: $PAGE_COUNT\nMemory size of TRANSPARENT HugePages is: $THP_POOL_SIZE\n"
