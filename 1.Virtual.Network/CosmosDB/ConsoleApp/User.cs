using System.Text.Json.Nodes;

using Microsoft.Azure.Cosmos;

namespace ConsoleApp
{
  public partial class Program
  {
    public static async Task<User[]> CreateUsersAsync(JsonNode databaseNode)
    {
      List<User> users = [];
      // TODO: Implement Cosmos DB Users creation
      return [.. users];
    }

    private static async Task<User?> CreateUserAsync(JsonNode databaseNode)
    {
      UserResponse? userResponse = null;
      // TODO: Implement Cosmos DB User creation
      return userResponse?.User;
    }
  }
}
