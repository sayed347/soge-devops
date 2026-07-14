#!/bin/sh
set -e

# Optional: fetch a config file from S3 before starting the app. Skipped
# gracefully in local/docker-compose mode where CONFIG_BUCKET is unset.
if [ -n "$CONFIG_BUCKET" ]; then
    echo "Fetching config from s3://${CONFIG_BUCKET}/${CONFIG_KEY:-app.properties}..."
    aws s3 cp "s3://${CONFIG_BUCKET}/${CONFIG_KEY:-app.properties}" /app/config/app.properties \
        || echo "WARN: could not fetch config from S3, continuing without it"
else
    echo "CONFIG_BUCKET not set, skipping S3 config fetch (local mode)"
fi

exec java -jar app.jar
