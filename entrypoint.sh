#!/bin/sh
set -e
DATE_HAPPENED=$(date +%s)
MD_PREFIX="%%% 
"
MD_SUFFIX="
 %%%"

if [[ -z "$DATADOG_API_KEY" || -z "$EVENT_TITLE" || -z "$EVENT_TEXT" ]]; then
  echo "One or more required variables are missing: DATADOG_API_KEY, EVENT_TITLE, EVENT_TEXT"
  exit 1
fi

if [[ -z "$EVENT_DATE_HAPPENED" ]]; then
  EVENT_DATE_HAPPENED=$DATE_HAPPENED
  echo "::notice file=entrypoint.sh,line=$LINENO::using calculated 'date_happened' $EVENT_DATE_HAPPENED"
fi

if [[ -z "$EVENT_PRIORITY" ]]; then
  # normal or low
  EVENT_PRIORITY="normal"
  echo "::notice file=entrypoint.sh,line=$LINENO::using default 'priority' $EVENT_PRIORITY"

fi

if [[ -z "$EVENT_ALERT_TYPE" ]]; then
  # error, warning, info, and success.
  EVENT_ALERT_TYPE="info"
  echo "::notice file=entrypoint.sh,line=$LINENO::using default 'alert_type' $EVENT_ALERT_TYPE"
fi

if [[ -z "$EVENT_SOURCE_TYPE" ]]; then
  # https://docs.datadoghq.com/integrations/faq/list-of-api-source-attribute-value/
  EVENT_SOURCE_TYPE="github"
  echo "::notice file=entrypoint.sh,line=$LINENO::using default 'source_type_name' $EVENT_SOURCE_TYPE"
fi

if [ "$DATADOG_US" = true ]; then
  # error, warning, info, and success.
  endpoint="https://api.datadoghq.com"
  echo "::notice file=entrypoint.sh,line=$LINENO::using US endpoint"
else
  endpoint="https://api.datadoghq.eu"
  echo "::notice file=entrypoint.sh,line=$LINENO::using EU endpoint"
fi

TXT="${MD_PREFIX}${EVENT_TEXT}${MD_SUFFIX}"
if [ "$USE_MARKDOWN" = false ]; then
  TXT="${EVENT_TEXT}"
  echo "::notice file=entrypoint.sh,line=$LINENO::disabled markdown formatting for ${TXT}"
fi

json=$(
  jq -cn \
    --arg alert_type "${EVENT_ALERT_TYPE}" \
    --argjson date_happened ${EVENT_DATE_HAPPENED} \
    --arg priority "${EVENT_PRIORITY}" \
    --arg source_type_name "${EVENT_SOURCE_TYPE}" \
    --arg title "${EVENT_TITLE}" \
    --arg text "${TXT}" \
    '$ARGS.named'
)
echo "::debug file=entrypoint.sh,line=$LINENO::$json"

if [[ -n "$EVENT_TAGS" ]]; then
  echo "::debug file=entrypoint.sh,line=$LINENO::EVENT_TAGS $EVENT_TAGS"
  json=$(echo $json | jq -c --argjson tags "${EVENT_TAGS}" '. + {tags: $tags}')
  echo "::notice file=entrypoint.sh,line=$LINENO::added EVENT_TAGS $EVENT_TAGS"
  echo "::debug file=entrypoint.sh,line=$LINENO::$json"
fi

if [[ -n "$EVENT_DEVICE_NAME" ]]; then
  echo "::debug file=entrypoint.sh,line=$LINENO::EVENT_DEVICE_NAME $EVENT_DEVICE_NAME"
  json=$(echo $json | jq -c --arg device_name "${EVENT_DEVICE_NAME}" '. + {device_name: $device_name}')
  echo "::notice file=entrypoint.sh,line=$LINENO::added EVENT_DEVICE_NAME $EVENT_DEVICE_NAME"
  echo "::debug file=entrypoint.sh,line=$LINENO::$json"
fi

if [[ -n "$EVENT_HOST" ]]; then
  echo "::debug file=entrypoint.sh,line=$LINENO::EVENT_HOST $EVENT_HOST"
  json=$(echo $json | jq -c --arg host "${EVENT_HOST}" '. + {host: $host}')
  echo "::notice file=entrypoint.sh,line=$LINENO::added EVENT_HOST $EVENT_HOST"
  echo "::debug file=entrypoint.sh,line=$LINENO::$json"
fi

if [[ -n "$EVENT_AGGREGATION_KEY" ]]; then
  echo "::debug file=entrypoint.sh,line=$LINENO::EVENT_AGGREGATION_KEY $EVENT_AGGREGATION_KEY"
  json=$(echo $json | jq -c --arg aggregation_key "${EVENT_AGGREGATION_KEY}" '. + {aggregation_key: $aggregation_key}')
  echo "::notice file=entrypoint.sh,line=$LINENO::added EVENT_AGGREGATION_KEY $EVENT_AGGREGATION_KEY"
  echo "::debug file=entrypoint.sh,line=$LINENO::$json"
fi

if [[ -n "$RELATED_EVENT_ID" ]]; then
  echo "::debug file=entrypoint.sh,line=$LINENO::RELATED_EVENT_ID $RELATED_EVENT_ID"
  json=$(echo $json | jq -c --arg parent_id "${RELATED_EVENT_ID}" '. + {related_event_id: $parent_id}')
  echo "::notice file=entrypoint.sh,line=$LINENO::added RELATED_EVENT_ID $RELATED_EVENT_ID"
  echo "::debug file=entrypoint.sh,line=$LINENO::$json"
fi

echo "::notice file=entrypoint.sh,line=$LINENO::sending event to Datadog"
echo "::debug file=entrypoint.sh,line=$LINENO::endpoint $endpoint"
echo "::debug file=entrypoint.sh,line=$LINENO::json $json"

if [ "$DRY_RUN" = true ]; then
  echo "::notice file=entrypoint.sh,line=$LINENO::dry-run enabled, skipping event creation"
  dryrunjson=$(
    echo $json | jq -c \
      --argjson id 1234567890 \
      --arg id_str "1234567890" \
      --arg url "https://app.datadoghq.com/event/event?id=1234567890" \
      --argjson payload "$json" \
      '. + {id: $id, id_str: $id_str, url: $url, payload: $payload}'

  )

  echo "::debug file=entrypoint.sh,line=$LINENO::dryrunjson $dryrunjson"

  response=$(
    jq -cn \
      --argjson event "$dryrunjson" \
      --arg status "ok" \
      '$ARGS.named'
  )
else
  response=$(curl -X POST "${endpoint}/api/v1/events" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -H "DD-API-KEY: ${DATADOG_API_KEY}" \
    -d "$json")
  echo "::debug file=entrypoint.sh,line=$LINENO::response $response"
fi

# outputs
{
  echo "json=$(echo $response | jq -rc '.')"
  echo "event_id=$(echo $response | jq -r '.event.id_str')"
  echo "event_url=$(echo $response | jq -r '.event.url')"
} >>"$GITHUB_OUTPUT"
