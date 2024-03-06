using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Configuration;

namespace ConsoleApp
{
  public partial class Program
  {
    public static async Task<Database[]> CreateDatabasesAsync()
    {
      List<Database> databases = [];
      CosmosDatabase[]? databasesConfig = _appConfig.GetSection("databases").Get<CosmosDatabase[]>();
      if (databasesConfig != null) {
        foreach (CosmosDatabase? databaseConfig in databasesConfig) {
          if (databaseConfig != null) {
            Database database = await CreateDatabaseAsync(databaseConfig);
            await Program.CreateContainersAsync(database, databaseConfig);
            databases.Add(database);
          }
        }
      }
      return [.. databases];
    }

    private static async Task<Database> CreateDatabaseAsync(CosmosDatabase databaseConfig)
    {
      DatabaseResponse databaseResponse;
      int? requestUnits = databaseConfig.Throughput?.RequestUnits;
      if (requestUnits == null || databaseConfig.Throughput == null) {
        databaseResponse = await _cosmosClient.CreateDatabaseIfNotExistsAsync(databaseConfig.Name);
      } else {
        ThroughputProperties throughputProperties;
        if (databaseConfig.Throughput.AutoScale) {
          throughputProperties = ThroughputProperties.CreateAutoscaleThroughput(requestUnits.Value);
        } else {
          throughputProperties = ThroughputProperties.CreateManualThroughput(requestUnits.Value);
        }
        databaseResponse = await _cosmosClient.CreateDatabaseIfNotExistsAsync(databaseConfig.Name, throughputProperties);
      }
      return databaseResponse.Database;
    }
  }
}
