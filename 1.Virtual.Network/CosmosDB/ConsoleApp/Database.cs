using ConfigException = System.Configuration.ConfigurationErrorsException;

using System.Text.Json;
using System.Text.Json.Nodes;

using Microsoft.Azure.Cosmos;

namespace ConsoleApp
{
  public partial class Program
  {
    public static async Task<Database[]> CreateDatabasesAsync()
    {
      List<Database> databases = [];
      string? jsonConfig = _configSettings["databases"] ?? throw new ConfigException("databases config");
      JsonArray? databaseNodes = JsonSerializer.Deserialize<JsonArray>(jsonConfig) ?? throw new ConfigException("databases json");
      foreach (JsonNode? databaseNode in databaseNodes) {
        if (databaseNode != null) {
          Database? database = await CreateDatabaseAsync(databaseNode);
          if (database != null) {
            databases.Add(database);
          }
        }
      }
      return [.. databases];
    }

    private static async Task<Database?> CreateDatabaseAsync(JsonNode databaseNode)
    {
      DatabaseResponse? databaseResponse = null;
      databaseNode.AsObject().TryGetPropertyValue("name", out JsonNode? jsonProperty);
      if (jsonProperty != null) {
        jsonProperty.AsValue().TryGetValue<string>(out string? databaseName);
        if (databaseName != null) {
          databaseNode.AsObject().TryGetPropertyValue("throughput", out JsonNode? jsonObject);
          if (jsonObject == null) {
            databaseResponse = await _cosmosClient.CreateDatabaseIfNotExistsAsync(databaseName);
          } else {
            jsonObject.AsObject().TryGetPropertyValue("requestUnits", out jsonProperty);
            if (jsonProperty == null) {
              databaseResponse = await _cosmosClient.CreateDatabaseIfNotExistsAsync(databaseName);
            } else {
              bool isValid = jsonProperty.AsValue().TryGetValue<int>(out int requestUnits);
              if (!isValid) {
                databaseResponse = await _cosmosClient.CreateDatabaseIfNotExistsAsync(databaseName);
              } else {
                ThroughputProperties throughputProperties;
                jsonObject.AsObject().TryGetPropertyValue("autoScale", out jsonProperty);
                if (jsonProperty == null) {
                  throughputProperties = ThroughputProperties.CreateManualThroughput(requestUnits);
                } else {
                  isValid = jsonProperty.AsValue().TryGetValue<bool>(out bool autoScale);
                  if (!isValid || !autoScale) {
                    throughputProperties = ThroughputProperties.CreateManualThroughput(requestUnits);
                  } else {
                    throughputProperties = ThroughputProperties.CreateAutoscaleThroughput(requestUnits);
                  }
                }
                databaseResponse = await _cosmosClient.CreateDatabaseIfNotExistsAsync(databaseName, throughputProperties);
              }
            }
          }
        }
      }
      await Program.CreateContainersAsync(databaseNode);
      return databaseResponse?.Database;
    }
  }
}
