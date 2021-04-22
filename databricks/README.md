
# Install Datadog as init script in Azure Databricks

These scripts to be applied as global initi script

- Metrics-script to send metrics to dogstats
- dogstatsd-remapper to remap those metrics. https://docs.datadoghq.com/developers/dogstatsd/dogstatsd_mapper/
- Worker and drive node to install the agent with logs, process and spark integraiton
