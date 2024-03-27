using Microsoft.Azure.Cosmos;

namespace ConsoleApp
{
  #pragma warning disable IDE1006 // Naming Styles
  public record CosmosItem
  {
    public string? id { get; set; }

    public string? tenantId { get; set; }

    public string? userId { get; set; }

    public string? sessionId { get; set; }

    public string? data {get; set;}
  }
  #pragma warning restore IDE1006 // Naming Styles

  public partial class Program
  {
    private static async Task<FeedIterator<T>> GetItemsAsync<T>(Container container, QueryDefinition queryDefinition, QueryRequestOptions? queryOptions = null) where T : CosmosItem
    {
      using FeedIterator<T> resultPages = container.GetItemQueryIterator<T>(queryDefinition, null, queryOptions);
      while (resultPages.HasMoreResults) {
        FeedResponse<T> resultPage = await resultPages.ReadNextAsync();
        foreach (T item in resultPage) {
          Console.WriteLine($"Found Item: {item.id}, Partition: {item.tenantId}, {item.userId}, {item.sessionId}, Container: {container.Id}");
        }
      }
      return resultPages;
    }

    private static async Task<FeedIterator<T>> GetItemsAsync<T>(Container container, string queryText, QueryRequestOptions? queryOptions = null) where T : CosmosItem
    {
      using FeedIterator<T> resultPages = container.GetItemQueryIterator<T>(queryText, null, queryOptions);
      while (resultPages.HasMoreResults) {
        FeedResponse<T> resultPage = await resultPages.ReadNextAsync();
        foreach (T item in resultPage) {
          Console.WriteLine($"Found Item: {item.id}, Partition: {item.tenantId}, {item.userId}, {item.sessionId}, Container: {container.Id}");
        }
      }
      return resultPages;
    }

    private static async Task<bool> ItemExistsAsync<T>(Container container, PartitionKey partitionKey, string itemId, ItemRequestOptions? itemOptions = null)
    {
      using ResponseMessage response = await container.ReadItemStreamAsync(itemId, partitionKey, itemOptions);
      return response.IsSuccessStatusCode;
    }

    private static async Task<double> CreateItemAsync<T>(Container container, PartitionKey partitionKey, T item, ItemRequestOptions? itemOptions = null)
    {
      ItemResponse<T> itemResponse = await container.CreateItemAsync<T>(item, partitionKey, itemOptions);
      return itemResponse.RequestCharge;
    }

    private static async Task<double> ReadItemAsync<T>(Container container, PartitionKey partitionKey, string itemId, ItemRequestOptions? itemOptions = null)
    {
      ItemResponse<T> itemResponse = await container.ReadItemAsync<T>(itemId, partitionKey, itemOptions);
      return itemResponse.RequestCharge;
    }

    private static async Task<double> ReplaceItemAsync<T>(Container container, PartitionKey partitionKey, string itemId, T item, ItemRequestOptions? itemOptions = null)
    {
      ItemResponse<T> itemResponse = await container.ReplaceItemAsync<T>(item, itemId, partitionKey, itemOptions);
      return itemResponse.RequestCharge;
    }

    private static async Task<double> UpsertItemAsync<T>(Container container, PartitionKey partitionKey, T item, ItemRequestOptions? itemOptions = null)
    {
      ItemResponse<T> itemResponse = await container.UpsertItemAsync<T>(item, partitionKey, itemOptions);
      return itemResponse.RequestCharge;
    }

    private static async Task<double> DeleteItemAsync<T>(Container container, PartitionKey partitionKey, string itemId, ItemRequestOptions? itemOptions = null)
    {
      ItemResponse<T> itemResponse = await container.DeleteItemAsync<T>(itemId, partitionKey, itemOptions);
      return itemResponse.RequestCharge;
    }

    private static async Task ProcessItemAsync(Container container, CosmosContainer containerConfig, string tenantId, string userId, string sessionId, string itemId, ItemRequestOptions? itemOptions = null)
    {
      CosmosItem item = new() {
        id = itemId,
        tenantId = tenantId,
        userId = userId,
        sessionId = sessionId,
        data = DateTime.UtcNow.ToString()
      };
      PartitionKeyBuilder partitionKeyBuilder = new();
      partitionKeyBuilder.Add(tenantId);
      if (containerConfig.PartitionKey != null && containerConfig.PartitionKey.Paths != null) {
        if (containerConfig.PartitionKey.Paths.Contains("/userId")) {
          partitionKeyBuilder.Add(userId);
        }
        if (containerConfig.PartitionKey.Paths.Contains("/sessionId")) {
          partitionKeyBuilder.Add(sessionId);
        }
      }
      PartitionKey partitionKey = partitionKeyBuilder.Build();
      double requestCharge;
      if (await ItemExistsAsync<CosmosItem>(container, partitionKey, itemId, itemOptions)) {
        requestCharge = await ReplaceItemAsync<CosmosItem>(container, partitionKey, itemId, item, itemOptions);
      } else {
        requestCharge = await CreateItemAsync<CosmosItem>(container, partitionKey, item, itemOptions);
      }
    }
  }
}
