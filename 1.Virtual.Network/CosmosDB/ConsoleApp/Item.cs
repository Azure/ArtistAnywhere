using Microsoft.Azure.Cosmos;

namespace ConsoleApp
{
  #pragma warning disable IDE1006 // Naming Styles
  public record CosmosItem
  {
    public string? id { get; set; }

    public string? type { get; set; }

    public string? data {get; set;}
  }
  #pragma warning restore IDE1006 // Naming Styles

  public partial class Program
  {
    private static async Task<bool> ItemExistsAsync<T>(Container container, PartitionKey partitionKey, string itemId)
    {
      using ResponseMessage response = await container.ReadItemStreamAsync(itemId, partitionKey);
      return response.IsSuccessStatusCode;
    }

    private static async Task<double> CreateItemAsync<T>(Container container, PartitionKey partitionKey, T item)
    {
      ItemResponse<T> itemResponse = await container.CreateItemAsync<T>(item, partitionKey);
      return itemResponse.RequestCharge;
    }

    private static async Task<double> ReadItemAsync<T>(Container container, PartitionKey partitionKey, string itemId)
    {
      ItemResponse<T> itemResponse = await container.ReadItemAsync<T>(itemId, partitionKey);
      return itemResponse.RequestCharge;
    }

    private static async Task<double> ReplaceItemAsync<T>(Container container, PartitionKey? partitionKey, string itemId, T item)
    {
      ItemResponse<T> itemResponse = await container.ReplaceItemAsync<T>(item, itemId, partitionKey);
      return itemResponse.RequestCharge;
    }

    private static async Task<double> UpsertItemAsync<T>(Container container, PartitionKey? partitionKey, T item)
    {
      ItemResponse<T> itemResponse = await container.UpsertItemAsync<T>(item, partitionKey);
      return itemResponse.RequestCharge;
    }

    private static async Task<double> DeleteItemAsync<T>(Container container, PartitionKey partitionKey, string itemId)
    {
      ItemResponse<T> itemResponse = await container.DeleteItemAsync<T>(itemId, partitionKey);
      return itemResponse.RequestCharge;
    }

    private static async Task ProcessItemAsync(Container container, string partitionId, string itemId)
    {
      PartitionKey partitionKey = new(partitionId);
      CosmosItem item = new() {
        id = itemId,
        type = partitionId,
        data = DateTime.UtcNow.ToString()
      };
      double requestCharge;
      if (await ItemExistsAsync<CosmosItem>(container, partitionKey, itemId)) {
        requestCharge = await ReplaceItemAsync<CosmosItem>(container, partitionKey, itemId, item);
      } else {
        requestCharge = await CreateItemAsync<CosmosItem>(container, partitionKey, item);
      }
    }
  }
}