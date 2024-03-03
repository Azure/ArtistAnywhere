using System.Text.Json.Nodes;

using Microsoft.Azure.Cosmos;

namespace ConsoleApp
{
  public partial class Program
  {
    public static async Task<Container[]> CreateContainersAsync(JsonNode databaseNode)
    {
      List<Container> containers = [];
      // TODO: Implement Cosmos DB Containers creation
      return [.. containers];
    }

    private static async Task<Container?> CreateContainerAsync(JsonNode databaseNode)
    {
      ContainerResponse? containerResponse = null;
      // TODO: Implement Cosmos DB Container creation
      await Program.CreateUsersAsync(databaseNode);
      return containerResponse?.Container;
    }
  }
}
