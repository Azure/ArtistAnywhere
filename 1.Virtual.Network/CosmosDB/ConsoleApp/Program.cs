using System.Text.Json;

using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Configuration;

namespace ConsoleApp
{
  public partial class Program
  {
    private static readonly IConfigurationRoot _appConfig;

    private static readonly CosmosClient _cosmosClient;

    static Program()
    {
      ConfigurationBuilder configBuilder = new();
      configBuilder.AddJsonFile("AppSettings.json");
      configBuilder.AddUserSecrets("f566a291-96ac-4cc3-8016-fb34a0c7b975");
      _appConfig = configBuilder.Build();

      string? accountEndpoint = _appConfig["accountEndpoint"];
      string? accountAuthKey = _appConfig["accountAuthKey"];

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
      JsonSerializerOptions jsonOptions = new() {
        WriteIndented = true
      };

      AccountProperties account = await _cosmosClient.ReadAccountAsync();
      Console.WriteLine("Account: {0}", JsonSerializer.Serialize(account, jsonOptions));

      Database[] databases = await Program.CreateDatabasesAsync();
      Console.WriteLine("Databases: {0}", JsonSerializer.Serialize(databases, jsonOptions));
    }
  }

  public class CosmosThroughput
  {
      public int RequestUnits { get; set; }

      public bool AutoScale { get; set; }
  }

  public class CosmosDatabase
  {
      public string? Name { get; set; }

      public CosmosThroughput? Throughput { get; set; }

      public CosmosContainer[]? Containers { get; set; }
  }

  public class CosmosContainer
  {
      public string? Name { get; set; }

      public CosmosThroughput? Throughput { get; set; }

      public string? PartitionKeyPath { get; set; }
  }
}
