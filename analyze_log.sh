#!/bin/bash

log="apache_logs.txt"

echo "----------------------------------"
echo "Step 1: Request Counts"
total=$(wc -l < "$log")
get=$(grep -c '"GET' "$log")
post=$(grep -c '"POST' "$log")
echo "Total requests: $total"
echo "GET requests: $get"
echo "POST requests: $post"

echo "----------------------------------"
echo "Step 2: Unique IP Addresses"
unique_ips=$(awk '{print $1}' "$log" | sort | uniq | wc -l)
echo "Total unique IPs: $unique_ips"
echo "GET and POST per IP:"
awk '{print $1, $6}' "$log" | grep -E '"(GET|POST)' | awk '{counts[$1 FS $2]++} END {for (c in counts) print c, counts[c]}' | column -t

echo "----------------------------------"
echo "Step 3: Failed Requests"
failures=$(awk '$9 ~ /^[45]/ {count++} END {print count}' "$log")
fail_percent=$(awk -v f="$failures" -v t="$total" 'BEGIN {printf "%.2f", (f/t)*100}')
echo "Failed requests: $failures"
echo "Failure percentage: $fail_percent%"

echo "----------------------------------"
echo "Step 4: Most Active IP"
awk '{print $1}' "$log" | sort | uniq -c | sort -nr | head -n 1

echo "----------------------------------"
echo "Step 5: Daily Request Averages"
awk -F'[:[]' '{print $2}' "$log" | cut -d: -f1 | sort | uniq -c
day_count=$(awk -F'[:[]' '{print $2}' "$log" | cut -d: -f1 | sort | uniq | wc -l)
average=$(awk -v t="$total" -v d="$day_count" 'BEGIN {printf "%.2f", t/d}')
echo "Average requests per day: $average"

echo "----------------------------------"
echo "Step 6: Days with Most Failures"
awk '$9 ~ /^[45]/ {print $4}' "$log" | cut -d: -f1 | tr -d "[" | sort | uniq -c | sort -nr | head

echo "----------------------------------"
echo "Step 7: Requests by Hour"
awk -F'[:[]' '{print $3}' "$log" | sort | uniq -c | sort -k2 -n | awk '{printf "Hour %02d: %4d requests\n", $2, $1}'

echo "----------------------------------"
echo "Step 8: Request Trends (Visualized)"
awk -F'[:[]' '{print $3}' "$log" | sort | uniq -c | sort -k2 -n | \
awk '{printf "Hour %02d: %4d | ", $2, $1; for(i=0;i<$1/10;i++) printf "#"; print ""}'

echo "----------------------------------"
echo "Additional - Status Code Breakdown"
awk '{codes[$9]++} END {for (code in codes) print code, codes[code]}' "$log" | sort

echo "----------------------------------"
echo "Additional - Most Active IP by GET"
grep '"GET' "$log" | awk '{print $1}' | sort | uniq -c | sort -nr | head -1
echo "Most Active IP by POST"
grep '"POST' "$log" | awk '{print $1}' | sort | uniq -c | sort -nr | head -1

echo "----------------------------------"
echo "Additional - Failure Patterns by Hour"
awk '$9 ~ /^[45]/ {split($4, a, ":"); print a[2]}' "$log" | sort | uniq -c | sort -nr
