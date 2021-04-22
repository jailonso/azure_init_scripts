#!/bin/bash
echo "Generate statsd remapper lines to separate file"

rm -v /tmp/dogstatsd-generated.yaml

cat <<EOF > /tmp/dogstatsd-generated.yaml

dogstatsd_mapper_profiles:
  - name: spark_extended
    prefix: spark_extended.
    mappings:
      - match: 'spark_extended.([\w-]+)\.driver\.(.+)'
        match_type: regex
        name: 'spark_extended.\$2'
        tags:
          spark_app_id: '\$1'
          spark_node_type: 'driver'
      - match: 'spark_extended.([\w-]+)\.([0-9]+)\.(.+)'
        match_type: regex
        name: 'spark_extended.\$3'
        tags:
          spark_app_id: '\$1'
          spark_node_id: '\$2'
          spark_node_type: 'executor'
EOF
