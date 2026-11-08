#!/usr/bin/env bash
#
# Ivan Angelov ivangotoy@gmail.com
# https://digtvbg.com/
#
# Check some HUGEPAGES counts. To be developed further.

PAGE_COUNT=$(rg -oNr '$1' '^nr_anon_transparent_hugepages\s+(\d+)' /proc/vmstat)
THP_POOL_SIZE=$(rg -oNr '$1' '^AnonHugePages:\s+(\d+ kB)' /proc/meminfo)

printf 'Number of TRANSPARENT HugePages is: %s\nMemory size of TRANSPARENT HugePages is: %s\n' "$PAGE_COUNT" "$THP_POOL_SIZE"
