using System.Collections.ObjectModel;

using Microsoft.Azure.Cosmos;

namespace ConsoleApp
{
  public class CosmosContainer
  {
    public string? Name { get; set; }

    public CosmosPartitionKey? PartitionKey { get; set; }

    public CosmosGeospatial? Geospatial { get; set; }

    public CosmosThroughput? Throughput { get; set; }

    public CosmosIndexPolicy? IndexPolicy { get; set; }

    public CosmosTimeToLive? TimeToLive { get; set; }
  }

  public class CosmosPartitionKey
  {
    public string? Version { get; set; }

    public string[]? Paths { get; set; }
  }

  public class CosmosGeospatial
  {
    public string? Type { get; set; }
  }

  public class CosmosIndexPolicy
  {
    public string? Mode { get; set; }

    public string[]? IncludedPaths { get; set; }

    public string[]? ExcludedPaths { get; set; }

    public string[]? SpatialPaths { get; set; }

    public CosmosIndexComposite[]? Composite { get; set; }
  }

  public class CosmosIndexComposite
  {
    public CosmosIndexCompositePath[]? Paths { get; set; }
  }

  public class CosmosIndexCompositePath
  {
    public string? Value { get; set; }

    public CompositePathSortOrder Order { get; set; }
  }

  public class CosmosTimeToLive
  {
    public int? Default { get; set; }

    public int? Analytics { get; set; }
  }

  public partial class Program
  {
    public static async Task<Container[]> CreateContainersAsync(Database database, CosmosDatabase databaseConfig)
    {
      List<Container> containers = [];
      if (databaseConfig.Containers != null) {
        foreach (CosmosContainer containerConfig in databaseConfig.Containers) {
          Container container = await CreateContainerAsync(database, containerConfig);
          containers.Add(container);
          string tenantId = "t1";
          string userId = "u1";
          string sessionId = "s1";
          string itemId = "i1";
          await ProcessItemAsync(container, containerConfig, tenantId, userId, sessionId, itemId);
          tenantId = "t2";
          userId = "u1";
          sessionId = "s1";
          itemId = "i1";
          await ProcessItemAsync(container, containerConfig, tenantId, userId, sessionId, itemId);
        }
      }
      return [.. containers];
    }

    private static async Task<Container> CreateContainerAsync(Database database, CosmosContainer containerConfig)
    {
      ContainerResponse containerResponse;
      ContainerProperties containerProperties = new() {
        Id = containerConfig.Name,
        DefaultTimeToLive = containerConfig.TimeToLive?.Default,
        AnalyticalStoreTimeToLiveInSeconds = containerConfig.TimeToLive?.Analytics
      };
      if (containerConfig.PartitionKey != null && containerConfig.PartitionKey.Paths != null) {
        if (containerConfig.PartitionKey.Paths.Length > 1) {
          containerProperties.PartitionKeyPaths = containerConfig.PartitionKey?.Paths;
        } else {
          containerProperties.PartitionKeyPath = containerConfig.PartitionKey?.Paths[0];
        }
      }
      if (Enum.TryParse<PartitionKeyDefinitionVersion>(containerConfig.PartitionKey?.Version, out PartitionKeyDefinitionVersion partitionKeyVersion)) {
        containerProperties.PartitionKeyDefinitionVersion = partitionKeyVersion;
      }
      if (Enum.TryParse<GeospatialType>(containerConfig.Geospatial?.Type, out GeospatialType geospatialType)) {
        containerProperties.GeospatialConfig.GeospatialType = geospatialType;
      }
      if (Enum.TryParse<IndexingMode>(containerConfig.IndexPolicy?.Mode, out IndexingMode indexingMode)) {
        containerProperties.IndexingPolicy.IndexingMode = indexingMode;
      }
      if (containerConfig.IndexPolicy != null) {
        if (containerConfig.IndexPolicy.IncludedPaths != null) {
          foreach (string includedPath in containerConfig.IndexPolicy.IncludedPaths) {
            containerProperties.IndexingPolicy.IncludedPaths.Add(new IncludedPath { Path = includedPath });
          }
        }
        if (containerConfig.IndexPolicy.ExcludedPaths != null) {
          foreach (string excludedPath in containerConfig.IndexPolicy.ExcludedPaths) {
            containerProperties.IndexingPolicy.ExcludedPaths.Add(new ExcludedPath { Path = excludedPath });
          }
        }
        if (containerConfig.IndexPolicy.SpatialPaths != null) {
          foreach (string spatialPath in containerConfig.IndexPolicy.SpatialPaths) {
            containerProperties.IndexingPolicy.SpatialIndexes.Add(new SpatialPath { Path = spatialPath });
          }
        }
        if (containerConfig.IndexPolicy.Composite != null) {
          foreach (CosmosIndexComposite compositeIndex in containerConfig.IndexPolicy.Composite) {
            if (compositeIndex.Paths != null) {
              Collection<CompositePath> compositePaths = [];
              foreach (CosmosIndexCompositePath indexPath in compositeIndex.Paths) {
                compositePaths.Add(new CompositePath { Path = indexPath.Value, Order = indexPath.Order });
              }
              containerProperties.IndexingPolicy.CompositeIndexes.Add(compositePaths);
            }
          }
        }
      }
      int? requestUnits = containerConfig.Throughput?.RequestUnits;
      if (requestUnits == null || containerConfig.Throughput == null) {
        containerResponse = await database.CreateContainerIfNotExistsAsync(containerProperties);
      } else {
        ThroughputProperties throughputProperties;
        if (containerConfig.Throughput.AutoScale) {
          throughputProperties = ThroughputProperties.CreateAutoscaleThroughput(requestUnits.Value);
        } else {
          throughputProperties = ThroughputProperties.CreateManualThroughput(requestUnits.Value);
        }
        containerResponse = await database.CreateContainerIfNotExistsAsync(containerProperties, throughputProperties);
      }
      return containerResponse.Container;
    }
  }
}
