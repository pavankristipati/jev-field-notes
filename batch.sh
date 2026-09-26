#!/bin/bash
# Ask Jev four yes/no questions about four movie reviews in ONE call,
# then print the answers, the cost, and the timing.
#
# Requires: a Vercel AI Gateway API key in the environment:
#   export AI_GATEWAY_API_KEY="your-key"
#
# Usage:
#   bash batch.sh

# Stop early with a clear message if the key is missing.
if [ -z "$AI_GATEWAY_API_KEY" ]; then
  echo "Set AI_GATEWAY_API_KEY first. See README.md."
  exit 1
fi

# Send the request. If the service is busy (HTTP 429),
# wait 2, 4, 8, 16, then 32 seconds between tries.
wait=2
for attempt in 1 2 3 4 5; do
  raw=$(curl -s -w '\nROUNDTRIP:%{time_total}' https://ai-gateway.vercel.sh/typesafe/v1/systemone \
    -H "Authorization: Bearer $AI_GATEWAY_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
      "model": "typesafe-ai/jev",
      "state": "Review 1: I went in with low expectations but the ending had me on the edge of my seat. I would watch it again. Review 2: The acting was fine but the plot dragged and I checked my phone twice. Review 3: Worst two hours of my year. Do not bother. Review 4: My brother loved it. I thought it was boring.",
      "questions": {
        "review_1": { "type": "noul", "instructions": "Is the writer of Review 1 recommending the movie?" },
        "review_2": { "type": "noul", "instructions": "Is the writer of Review 2 recommending the movie?" },
        "review_3": { "type": "noul", "instructions": "Is the writer of Review 3 recommending the movie?" },
        "review_4": { "type": "noul", "instructions": "Is the writer of Review 4 recommending the movie?" }
      }
    }')

  if echo "$raw" | grep -q rate_limit_exceeded; then
    echo "busy, waiting $wait seconds (attempt $attempt)"
    sleep $wait
    wait=$((wait * 2))
  else
    break
  fi
done

# Pull each answer out of the response, e.g. "review_1  0.94".
answers=$(echo "$raw" | grep -o '"review_[0-9]":{"type":"noul","noul":[0-9.e-]*' | sed -E 's/"(review_[0-9])".*"noul":/\1  /')

if [ -z "$answers" ]; then
  echo "ERROR. Response was: $raw"
  exit 1
fi

# Pull cost and timing fields out of the response.
tokens=$(echo "$raw" | grep -o '"input_tokens":[0-9]*' | cut -d: -f2)
market=$(echo "$raw" | grep -o '"marketCost":"[0-9.e-]*"' | cut -d'"' -f4)
charged=$(echo "$raw" | grep -o '"cost":"[0-9.e-]*"' | cut -d'"' -f4)
start=$(echo "$raw" | grep -o '"startTime":[0-9]*' | tail -1 | cut -d: -f2)
end=$(echo "$raw" | grep -o '"endTime":[0-9]*' | tail -1 | cut -d: -f2)
roundtrip=$(echo "$raw" | grep -o 'ROUNDTRIP:[0-9.]*' | cut -d: -f2)

# Decimal math with awk. "-v" passes values in, and "</dev/null"
# stops awk from waiting for keyboard input.
per_question=$(awk -v m="$market" 'BEGIN{printf "%.10f", m/4}' </dev/null)
roundtrip_ms=$(awk -v r="$roundtrip" 'BEGIN{printf "%d", r*1000}' </dev/null)

if [ -n "$start" ] && [ -n "$end" ]; then
  provider_ms="$((end - start)) ms"
else
  provider_ms="not reported"
fi

echo "$answers"
echo "----------------------------------------"
echo "Input tokens:         $tokens"
echo "List price, call:     \$$market"
echo "List price, question: \$$per_question"
echo "Charged:              \$$charged"
echo "Provider time:        $provider_ms"
echo "Round-trip time:      $roundtrip_ms ms"
