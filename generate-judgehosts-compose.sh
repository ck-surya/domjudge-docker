#!/bin/bash

# Number of judgehosts to deploy (passed as the first argument)
NUM_JUDGEHOSTS=$1

if [ -z "$NUM_JUDGEHOSTS" ]; then
  echo "Please provide the number of judgehost instances to deploy."
  echo "Usage: ./generate-compose.sh <num_instances>"
  exit 1
fi

# Start with an empty docker-compose.yml file
> judgehost.yml

# Copy the static parts of the docker-compose.yml file (if any)
cat <<EOF >> judgehost.yml
services:
EOF

# Loop through and create judgehost instances
for ((i=1; i<=NUM_JUDGEHOSTS; i++))
do
  # Replace the placeholder {{ID}} with the actual number
  sed "s/{{ID}}/$i/g" judgehost.template.yml >> judgehost.yml
done

cat <<EOF >> judgehost.yml
networks:
  domjudge-network:
    name: domjudge-network
    external: true
EOF

# Now you can use docker-compose up to launch all instances
docker compose -f judgehost.yml up -d