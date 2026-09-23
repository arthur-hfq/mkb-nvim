#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  [MARKAB] DOCKER-ISOLATED API STRESS TEST ENGINE                ║
# ║  Spins up a resource-constrained container, boots the server,   ║
# ║  runs the load test from the HOST, and generates a report.      ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# Usage: markab_docker_stress.sh <project_dir> <cpus> <memory> <start_cmd> <port> <route> <method> <count> <concurrency> <timeout> [json_body]

set -euo pipefail

PROJECT_DIR="$1"
CPUS="$2"
MEMORY="$3"
START_CMD="$4"
PORT="$5"
ROUTE="$6"
METHOD="$7"
COUNT="$8"
CONCURRENCY="$9"
TIMEOUT="${10}"
BODY="${11:-}"

CONTAINER_NAME="markab_stress_$(date +%s)"
HOST_PORT=$((49152 + RANDOM % 16384))
IMAGE=""
DOCKERFILE_TMP="/tmp/markab_stress_dockerfile_$$"

# ── PRE-FLIGHT CLEANUP ───────────────────────────────────────────
# Ensure no orphaned containers are left behind from aborted tests
ORPHANS=$(docker ps -a -q -f name=markab_stress_)
if [ -n "$ORPHANS" ]; then
  echo "┌─ CLEANING UP ORPHANED CONTAINERS ─────────────────────────────┐"
  echo "  Killing lingering containers from previous aborted tests..."
  # Word splitting on $ORPHANS is intended here to pass multiple IDs
  docker rm -f $ORPHANS >/dev/null 2>&1
  echo "└───────────────────────────────────────────────────────────────┘"
  echo ""
fi

# Set a trap to clean up the CURRENT container if aborted mid-flight (e.g., closing Neovim panel)
trap 'echo -e "\n\n  [ABORTED] Cleaning up container $CONTAINER_NAME..."; docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1; exit 1' SIGINT SIGTERM

# ── AUTO-DETECT PROJECT RUNTIME ──────────────────────────────────
detect_image() {
  if [ -f "$PROJECT_DIR/package.json" ]; then
    IMAGE="node:22-alpine"
    WORKDIR="/app"
  elif [ -f "$PROJECT_DIR/requirements.txt" ] || [ -f "$PROJECT_DIR/Pipfile" ] || [ -f "$PROJECT_DIR/pyproject.toml" ]; then
    IMAGE="python:3.12-slim"
    WORKDIR="/app"
  elif [ -f "$PROJECT_DIR/go.mod" ]; then
    IMAGE="golang:1.23-alpine"
    WORKDIR="/app"
  elif [ -f "$PROJECT_DIR/composer.json" ]; then
    IMAGE="php:8.3-cli"
    WORKDIR="/app"
  elif [ -f "$PROJECT_DIR/Cargo.toml" ]; then
    IMAGE="rust:1.79-slim"
    WORKDIR="/app"
  elif [ -f "$PROJECT_DIR/Gemfile" ]; then
    IMAGE="ruby:3.3-slim"
    WORKDIR="/app"
  else
    IMAGE="alpine:latest"
    WORKDIR="/app"
  fi
}

detect_image

# ── HEADER ───────────────────────────────────────────────────────
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  [MARKAB] DOCKER-ISOLATED STRESS TEST                        ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  PROJECT  : $(basename "$PROJECT_DIR")"
echo "║  IMAGE    : ${IMAGE}"
echo "║  LIMITS   : ${CPUS} CPU | ${MEMORY} RAM"
echo "║  SERVER   : ${START_CMD}"
echo "║  ENDPOINT : ${METHOD} http://localhost:${HOST_PORT}${ROUTE}"
echo "║  REQUESTS : ${COUNT}"
if [ -n "$BODY" ]; then
echo "║  BODY     : ${BODY}"
fi
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ── PHASE 1: BUILD ───────────────────────────────────────────────
echo "┌─ PHASE 1: PREPARING CONTAINER ─────────────────────────────┐"
echo "  Using pre-built image: ${IMAGE}"
echo "  Mounting local project: ${PROJECT_DIR} -> ${WORKDIR}"
echo "└───────────────────────────────────────────────────────────────┘"
echo ""

# ── PHASE 2: START CONTAINER ─────────────────────────────────────
echo "┌─ PHASE 2: STARTING CONTAINER (${CPUS} CPU / ${MEMORY} RAM) ┐"
docker run -d \
  --name "$CONTAINER_NAME" \
  --cpus="$CPUS" \
  --memory="$MEMORY" \
  --add-host=host.docker.internal:host-gateway \
  -v "${PROJECT_DIR}:${WORKDIR}" \
  -w "${WORKDIR}" \
  -p "${HOST_PORT}:${PORT}" \
  "${IMAGE}" sh -c "${START_CMD}" 2>&1

echo "  Container: ${CONTAINER_NAME}"
echo "  Mapped port: host:${HOST_PORT} -> container:${PORT}"
echo "└───────────────────────────────────────────────────────────────┘"
echo ""

# ── PHASE 3: WAIT FOR SERVER READY ───────────────────────────────
echo "┌─ PHASE 3: WAITING FOR SERVER TO BE READY ─────────────────┐"
MAX_WAIT=30
READY=0
for i in $(seq 1 $MAX_WAIT); do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:${HOST_PORT}${ROUTE}" 2>/dev/null || echo "000")
  if [ "$HTTP_CODE" != "000" ]; then
    echo "  Server responded with HTTP ${HTTP_CODE} after ${i}s"
    READY=1
    break
  fi
  printf "  Waiting... (%d/%ds)\r" "$i" "$MAX_WAIT"
  sleep 1
done

if [ "$READY" -eq 0 ]; then
  echo ""
  echo "  [ERROR] Server did not respond within ${MAX_WAIT}s"
  echo ""
  echo "┌─ CONTAINER LOGS ─────────────────────────────────────────────┐"
  docker logs "$CONTAINER_NAME" 2>&1 | tail -20
  echo "└──────────────────────────────────────────────────────────────┘"
  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1
  docker rmi "$CONTAINER_NAME" >/dev/null 2>&1
  rm -f "$DOCKERFILE_TMP"
  exit 1
fi
echo "└───────────────────────────────────────────────────────────────┘"
echo ""

# ── PHASE 4: CAPTURE BASELINE METRICS ───────────────────────────
echo "┌─ PHASE 4: BASELINE CONTAINER METRICS ─────────────────────┐"
BASELINE_STATS=$(docker stats "$CONTAINER_NAME" --no-stream --format "CPU: {{.CPUPerc}} | MEM: {{.MemUsage}} | NET: {{.NetIO}}" 2>/dev/null || echo "N/A")
echo "  IDLE: ${BASELINE_STATS}"
echo "└───────────────────────────────────────────────────────────────┘"
echo ""

# ── PHASE 5: FIRE STRESS TEST (PARALLEL) ───────────────────────────
echo "┌─ PHASE 5: FIRING ${COUNT} REQUESTS IN PARALLEL ────────────────┐"
echo ""

TMP_STATS="/tmp/markab_stress_stats_$$"
> "$TMP_STATS"
(
  while true; do
    docker stats "$CONTAINER_NAME" --no-stream --format "{{.CPUPerc}}*{{.MemUsage}}" 2>/dev/null >> "$TMP_STATS" || true
    sleep 0.2
  done
) &
STATS_PID=$!

export TARGET_URL="http://localhost:${HOST_PORT}${ROUTE}"
export METHOD
export BODY
export TIMEOUT
TOTAL=$COUNT

SUCCESS=0
FAIL=0
TOTAL_TIME=0
MIN_TIME=999999
MAX_TIME=0
HTTP_2XX=0
HTTP_3XX=0
HTTP_4XX=0
HTTP_5XX=0
declare -a TIMES
declare -a CODES

TMP_RESULTS="/tmp/markab_stress_results_$$"

WALL_START=$(date +%s%N)

seq 1 $TOTAL | xargs -P $CONCURRENCY -I {} bash -c '
  REQ_ID={}
  START=$(date +%s%N)
  if [ -n "$BODY" ]; then
    HTTP_CODE=$(curl --max-time "$TIMEOUT" -s -o /dev/null -w "%{http_code}" -X "$METHOD" -d "$BODY" -H "Content-Type: application/json" "$TARGET_URL" 2>/dev/null || echo "000")
  else
    HTTP_CODE=$(curl --max-time "$TIMEOUT" -s -o /dev/null -w "%{http_code}" -X "$METHOD" "$TARGET_URL" 2>/dev/null || echo "000")
  fi
  END=$(date +%s%N)
  ELAPSED=$(( (END - START) / 1000000 ))

  if [ "$HTTP_CODE" -ge 200 ] 2>/dev/null && [ "$HTTP_CODE" -lt 300 ] 2>/dev/null; then STATUS="[OK ]"
  elif [ "$HTTP_CODE" -ge 300 ] 2>/dev/null && [ "$HTTP_CODE" -lt 400 ] 2>/dev/null; then STATUS="[3XX]"
  elif [ "$HTTP_CODE" -ge 400 ] 2>/dev/null && [ "$HTTP_CODE" -lt 500 ] 2>/dev/null; then STATUS="[4XX]"
  else STATUS="[5XX]"; fi

  printf "  REQ %03d | HTTP %s | %5dms | %s\n" "$REQ_ID" "$HTTP_CODE" "$ELAPSED" "$STATUS"

  echo "$REQ_ID $HTTP_CODE $ELAPSED" >> "$1"
' _ "$TMP_RESULTS"

WALL_END=$(date +%s%N)
WALL_ELAPSED=$(( (WALL_END - WALL_START) / 1000000 ))

kill $STATS_PID 2>/dev/null || true
wait $STATS_PID 2>/dev/null || true

while read -r REQ_ID HTTP_CODE ELAPSED; do
  TIMES+=($ELAPSED)
  CODES+=($HTTP_CODE)
  TOTAL_TIME=$((TOTAL_TIME + ELAPSED))

  if [ "$HTTP_CODE" -ge 200 ] 2>/dev/null && [ "$HTTP_CODE" -lt 300 ] 2>/dev/null; then
    SUCCESS=$((SUCCESS + 1)); HTTP_2XX=$((HTTP_2XX + 1))
  elif [ "$HTTP_CODE" -ge 300 ] 2>/dev/null && [ "$HTTP_CODE" -lt 400 ] 2>/dev/null; then
    SUCCESS=$((SUCCESS + 1)); HTTP_3XX=$((HTTP_3XX + 1))
  elif [ "$HTTP_CODE" -ge 400 ] 2>/dev/null && [ "$HTTP_CODE" -lt 500 ] 2>/dev/null; then
    FAIL=$((FAIL + 1)); HTTP_4XX=$((HTTP_4XX + 1))
  else
    FAIL=$((FAIL + 1)); HTTP_5XX=$((HTTP_5XX + 1))
  fi

  if [ "$ELAPSED" -lt "$MIN_TIME" ]; then MIN_TIME=$ELAPSED; fi
  if [ "$ELAPSED" -gt "$MAX_TIME" ]; then MAX_TIME=$ELAPSED; fi
done < <(sort -n -k1 "$TMP_RESULTS")

rm -f "$TMP_RESULTS"

echo "  Done! $TOTAL requests sent (Concurrency: $CONCURRENCY)"
echo ""
echo "└───────────────────────────────────────────────────────────────┘"
echo ""

# ── PHASE 6: CAPTURE PEAK METRICS ───────────────────────────────
echo "┌─ PHASE 6: PEAK CONTAINER METRICS ─────────────────────────┐"
PEAK_STATS=$(docker stats "$CONTAINER_NAME" --no-stream --format "CPU: {{.CPUPerc}} | MEM: {{.MemUsage}} | NET: {{.NetIO}}" 2>/dev/null || echo "N/A")
echo "  PEAK: ${PEAK_STATS}"
echo "└───────────────────────────────────────────────────────────────┘"
echo ""

# ── PHASE 7: REPORT ─────────────────────────────────────────────
AVG=$((TOTAL_TIME / TOTAL))

# Calculate P95 (sort times, pick 95th percentile)
IFS=$'\n' SORTED_TIMES=($(sort -n <<<"${TIMES[*]}")); unset IFS
P95_IDX=$(( (TOTAL * 95 / 100) - 1 ))
if [ "$P95_IDX" -lt 0 ]; then P95_IDX=0; fi
P95=${SORTED_TIMES[$P95_IDX]:-$AVG}

# Calculate P99
P99_IDX=$(( (TOTAL * 99 / 100) - 1 ))
if [ "$P99_IDX" -lt 0 ]; then P99_IDX=0; fi
P99=${SORTED_TIMES[$P99_IDX]:-$AVG}

# Requests per second (Based on Wall Clock Time)
if [ "$WALL_ELAPSED" -gt 0 ]; then
  RPS=$(echo "scale=2; $TOTAL * 1000 / $WALL_ELAPSED" | bc 2>/dev/null || echo "N/A")
else
  RPS="INF"
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  [MARKAB] STRESS TEST REPORT                                 ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║"
printf "║  ENVIRONMENT : Docker (%-4s CPU | %-6s RAM)\n" "$CPUS" "$MEMORY"
printf "║  TOTAL REQS  : %d\n" "$TOTAL"
printf "║  SUCCESS     : %d (%d%%)\n" "$SUCCESS" "$((SUCCESS * 100 / TOTAL))"
printf "║  FAILED      : %d (%d%%)\n" "$FAIL" "$((FAIL * 100 / TOTAL))"
echo "║"
draw_bar() {
  local val=$1
  local total=$2
  local width=20
  if [ "$total" -eq 0 ]; then
    echo -n ""
    return
  fi
  local blocks=$(( val * width / total ))
  local bar=""
  for ((i=0; i<blocks; i++)); do bar="${bar}█"; done
  echo -n "$bar"
}

echo "╠── HTTP STATUS VISUALIZER ──────────────────────────────────╣"
printf "║  2XX (OK)      : %-4d │ %s\n" "$HTTP_2XX" "$(draw_bar "$HTTP_2XX" "$TOTAL")"
printf "║  3XX (Redirect): %-4d │ %s\n" "$HTTP_3XX" "$(draw_bar "$HTTP_3XX" "$TOTAL")"
printf "║  4XX (Client)  : %-4d │ %s\n" "$HTTP_4XX" "$(draw_bar "$HTTP_4XX" "$TOTAL")"
printf "║  5XX (Server)  : %-4d │ %s\n" "$HTTP_5XX" "$(draw_bar "$HTTP_5XX" "$TOTAL")"
echo "║"
echo "╠── LATENCY ─────────────────────────────────────────────────╣"
printf "║  AVG     : %dms\n" "$AVG"
printf "║  MIN     : %dms\n" "$MIN_TIME"
printf "║  MAX     : %dms\n" "$MAX_TIME"
printf "║  P95     : %dms\n" "$P95"
printf "║  P99     : %dms\n" "$P99"
echo "║"
echo "╠── THROUGHPUT ──────────────────────────────────────────────╣"
printf "║  REQ/SEC    : %s\n" "$RPS"
printf "║  TOTAL TIME : %dms\n" "$TOTAL_TIME"
echo "║"
echo "╠── CONTAINER RESOURCES (LIVE PROFILING) ────────────────────╣"
echo "║  IDLE : ${BASELINE_STATS}"
if [ -f "$TMP_STATS" ] && [ -s "$TMP_STATS" ]; then
  # Calculate Max RAM
  MAX_MEM=$(awk -F'*' '{print $2}' "$TMP_STATS" | awk -F' / ' '{print $1}' | sort -hr | head -n1)
  
  # Process and render timeline with normalized CPU
  # Docker reports % of host CPU. If limit is 0.5, max possible is 50%.
  # We normalize it so 50% = 100% capacity.
  echo "║"
  echo "║  CPU LOAD TIMELINE (Capacity Reached %):"
  
  awk -v limit="$CPUS" -F'*' '
  {
    cpu=$1; gsub(/%/, "", cpu);
    norm_cpu = (cpu / (limit * 100)) * 100;
    if (norm_cpu > max_cpu) max_cpu = norm_cpu;
    
    bar_len = int(norm_cpu / 5);
    if(bar_len > 20) bar_len = 20;
    bar = "";
    for(i=0; i<bar_len; i++) bar = bar "█";
    
    printf "║    %-6s |%s\n", sprintf("%.1f%%", norm_cpu), bar;
  }
  END {
    if (max_cpu == "") max_cpu = 0.0;
    printf "║\n║  MAX CPU : %.1f%% (Normalized)\n", max_cpu;
  }' "$TMP_STATS" | head -n 25
  
  printf "║  MAX RAM : %s\n" "$MAX_MEM"
  
  if [ $(wc -l < "$TMP_STATS") -gt 25 ]; then
    echo "║    ... (timeline truncated for brevity)"
  fi
else
  echo "║  PEAK : ${PEAK_STATS}"
fi
echo "║"
rm -f "$TMP_STATS"
echo "╚══════════════════════════════════════════════════════════════╝"

# ── CLEANUP ──────────────────────────────────────────────────────
echo ""
echo "┌─ CLEANUP ──────────────────────────────────────────────────┐"
docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 && echo "  Container removed: ${CONTAINER_NAME}"
echo "└───────────────────────────────────────────────────────────────┘"
