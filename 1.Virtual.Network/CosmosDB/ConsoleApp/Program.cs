using Azure.Identity;

using System.Text.Json;

using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Configuration;

namespace ConsoleApp
{
   public class CosmosAccount
  {
    public string? Endpoint { get; set; }

    public string? Key { get; set; }
  }

  public class CosmosThroughput
  {
    public int? RequestUnits { get; set; }

    public bool AutoScale { get; set; }
  }

  public partial class Program
  {
    private static readonly IConfigurationRoot _appConfig;

    private static readonly CosmosClient _cosmosClient;

    static Program()
    {
      ConfigurationBuilder configBuilder = new();
      configBuilder.AddJsonFile("AppSettings.json");
      _appConfig = configBuilder.Build();

      #pragma warning disable CS8600 // Converting null literal or possible null value to non-nullable type.
      CosmosAccount account = _appConfig.GetSection("account").Get<CosmosAccount>();
      #pragma warning restore CS8600 // Converting null literal or possible null value to non-nullable type.

      CosmosClientOptions cosmosOptions = new() {
        //ConnectionMode = ConnectionMode.Direct;
        //ConsistencyLevel = ConsistencyLevel.Session;
        //ApplicationPreferredRegions = ["WestUS","EastUS"];
        //ApplicationRegion = "WestUS";
        //AllowBulkExecution = false;
        //PriorityLevel = null;
      };

      #pragma warning disable CS8602 // Dereference of a possibly null reference.
      if (account.Key != null) {
        _cosmosClient = new CosmosClient(account.Endpoint, account.Key, cosmosOptions);
      } else {
        DefaultAzureCredentialOptions authTokenOptions = new() {
          ExcludeInteractiveBrowserCredential = true
        };
        DefaultAzureCredential authToken = new(authTokenOptions);
        _cosmosClient = new CosmosClient(account.Endpoint, authToken, cosmosOptions);
      }
      #pragma warning restore CS8602 // Dereference of a possibly null reference.
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
}
