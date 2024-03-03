using System.Text.Json;

using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Configuration;

namespace ConsoleApp
{
  public partial class Program
  {
    private static readonly IConfigurationRoot _configSettings;

    private static readonly CosmosClient _cosmosClient;

    static Program()
    {
      ConfigurationBuilder configBuilder = new();
      configBuilder.AddUserSecrets("93e3f543-4dd8-46b5-b24e-2c03ba48b294");
      _configSettings = configBuilder.Build();

      string? accountEndpoint = _configSettings["accountEndpoint"];
      string? accountAuthKey = _configSettings["accountAuthKey"];

      CosmosClientOptions cosmosOptions = new();
      //cosmosOptions.ConnectionMode = ConnectionMode.Direct;
      //cosmosOptions.ConsistencyLevel = ConsistencyLevel.Session;
      //cosmosOptions.ApplicationPreferredRegions = ["WestUS2","EastUS"];
      //cosmosOptions.ApplicationRegion = "WestUS2";
      //cosmosOptions.AllowBulkExecution = false;
      //cosmosOptions.PriorityLevel = null;

      _cosmosClient = new CosmosClient(accountEndpoint, accountAuthKey, cosmosOptions);
    }

    public static async Task Main(string[] args)
    {
      JsonSerializerOptions jsonOptions = new();
      jsonOptions.WriteIndented = true;

      AccountProperties account = await _cosmosClient.ReadAccountAsync();
      Console.WriteLine("Account: {0}", JsonSerializer.Serialize(account, jsonOptions));

      Database[] databases = await Program.CreateDatabasesAsync();
      Console.WriteLine("Databases: {0}", JsonSerializer.Serialize(databases, jsonOptions));
    }
  }
}
