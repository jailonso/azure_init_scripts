#!/bin/bash
echo "Script start."
echo "Running on the driver? $DB_IS_DRIVER"
echo "Driver ip: $DB_DRIVER_IP"

rm /tmp/start_datadog_on_worker.sh

cat <<EOF > /tmp/start_datadog_on_worker.sh
#!/bin/bash
DD_API_KEY="xxxx"
DD_SITE="datadoghq.com"

DATADOG_ROOT_PATH="/etc/datadog-agent"

echo "DB_IS_DRIVER = "\$DB_IS_DRIVER

if [ \$DB_IS_DRIVER = 'FALSE' ]; then
  echo "On the worker. Installing Datadog ..."

  # install the Datadog agent
  DD_AGENT_MAJOR_VERSION=7 DD_API_KEY=\$DD_API_KEY DD_SITE="\$DD_SITE" bash -c "\$(curl -L https://raw.githubusercontent.com/DataDog/datadog-agent/master/cmd/agent/install_script.sh)"

  chown dd-agent /etc/datadog-agent/auth

  # Enable logs, process and network collection
  sudo -u dd-agent echo "
logs_enabled: true
process_config:
  enabled: \"true\"

tags:
  - role:worker
  - vendor:databricks
  - cloud_provider:azure
  - db_shard_name:\$DB_SHARD_NAME
  - db_cluster_id:\$DB_CLUSTER_ID
  - db_cluster_name:\$DB_CLUSTER_NAME
  - db_instance_type:\$DB_INSTANCE_TYPE
  - db_runtime_version:\$DATABRICKS_RUNTIME_VERSION

use_dogstatsd: true
dogstatsd_port: 8125" >> /etc/datadog-agent/datadog.yaml

cat /tmp/dogstatsd-generated.yaml >> /etc/datadog-agent/datadog.yaml

  # Enable spark integration for streaming spark metrics
sudo -u dd-agent echo -e "\nEnabling spark integration..."
  echo "init_config:
  service: databricks1
instances:
  - spark_url: http://\$DB_DRIVER_IP:\$DB_DRIVER_PORT
    spark_cluster_mode: spark_standalone_mode
    cluster_name: \$current
logs:
  - type: file
    path: /databricks/driver/logs/*.log
    source: spark" > /etc/datadog-agent/conf.d/spark.d/conf.yaml

  # Restart datadog agent
  sudo service datadog-agent-sysprobe start
  sudo service datadog-agent stop
  sudo service datadog-agent start
  sudo service enable datadog-agent-sysprobe
fi
EOF


# # CLEANING UP
if [[ $DB_IS_DRIVER = "FALSE" ]]; then
  echo "On Worker!"
  echo "Running command: chmod a+x /tmp/start_datadog_on_worker.sh"
  chmod a+x /tmp/start_datadog_on_worker.sh
  echo "Running command: /tmp/start_datadog_on_worker.sh > /tmp/datadog_start_on_worker.log 2>&1 & disown"
  /tmp/start_datadog_on_worker.sh > /tmp/datadog_start_on_worker.log 2>&1 & disown
  echo "Done."
fi
echo "Script end."
