using Microsoft.Azure.Cosmos;

namespace ConsoleApp
{
  public partial class Program
  {
    public static async Task<Container[]> CreateContainersAsync(Database database, CosmosDatabase databaseConfig)
    {
      List<Container> containers = [];
      if (databaseConfig.Containers != null) {
        foreach (CosmosContainer containerConfig in databaseConfig.Containers) {
          Container container = await CreateContainerAsync(database, containerConfig);
          containers.Add(container);
        }
      }
      return [.. containers];
    }

    private static async Task<Container> CreateContainerAsync(Database database, CosmosContainer containerConfig)
    {
      ContainerResponse containerResponse;
      ContainerProperties containerProperties = new() {
        Id = containerConfig.Name,
        PartitionKeyPath = containerConfig.PartitionKeyPath
      };
      int? requestUnits = containerConfig.Throughput?.RequestUnits;
      if (requestUnits == null || containerConfig.Throughput == null) {
        containerResponse = await database.CreateContainerIfNotExistsAsync(containerProperties);
      } else {
        ThroughputProperties throughputProperties;
        if (containerConfig.Throughput.AutoScale) {
          throughputProperties = ThroughputProperties.CreateAutoscaleThroughput(requestUnits.Value);
        } else {
          throughputProperties = ThroughputProperties.CreateManualThroughput(requestUnits.Value);
        }
        containerResponse = await database.CreateContainerIfNotExistsAsync(containerProperties, throughputProperties);
      }
      return containerResponse.Container;
    }
  }
}
