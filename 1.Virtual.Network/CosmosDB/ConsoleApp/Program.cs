using System.Reflection;
using System.Text.Json;

using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Configuration;

namespace ConsoleApp
{
  public class Program
  {
    private static CosmosClient _cosmos;

    public static void Main(string[] args)
    {
      ConfigurationBuilder configBuilder = new();
      configBuilder.AddUserSecrets("93e3f543-4dd8-46b5-b24e-2c03ba48b294");

      IConfigurationRoot configSettings = configBuilder.Build();
      string? accountEndpoint = configSettings["accountEndpoint"];
      string? authKeyOrToken  = configSettings["authKeyOrToken"];

      CosmosClientOptions cosmosOptions = new();
      cosmosOptions.ConnectionMode = ConnectionMode.Direct;
      cosmosOptions.ConsistencyLevel = ConsistencyLevel.Session;
      cosmosOptions.ApplicationPreferredRegions = ["WestUS2","EastUS"];
      //cosmosOptions.ApplicationRegion = "WestUS2";
      cosmosOptions.PriorityLevel = PriorityLevel.Low;
      cosmosOptions.AllowBulkExecution = false;

      _cosmos = new CosmosClient(accountEndpoint, authKeyOrToken, cosmosOptions);

      Task mainTask = MainAsync(configSettings);
      mainTask.Wait();
    }

    private static async Task MainAsync(IConfigurationRoot configSettings)
    {
      JsonSerializerOptions jsonOptions = new();
      jsonOptions.WriteIndented = true;

      AccountProperties account = await _cosmos.ReadAccountAsync();
      Console.WriteLine("Account: {0}", JsonSerializer.Serialize(account, jsonOptions));

      string? databaseName = configSettings["databaseName"];
      string? containerName  = configSettings["containerName"];

      if (databaseName != null) {
        Database database = _cosmos.GetDatabase(databaseName);
        Console.WriteLine("Database: {0}", JsonSerializer.Serialize(database, jsonOptions));

        if (containerName != null) {
          ContainerProperties containerProperties = new();
          containerProperties.Id = containerName;
          containerProperties.PartitionKeyPath = "/id";

          Container container = await database.CreateContainerIfNotExistsAsync(containerProperties);
          Console.WriteLine("Container: {0}", JsonSerializer.Serialize(container, jsonOptions));
        }
      }
    }
  }
}
