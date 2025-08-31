
defplanet GraphNode do
  orbitals do
    moon id :: String.t()
    moon label :: String.t()
    moon properties :: map()
    moon importance_score :: float()
    moon activity_level :: float()
    moon created_at :: DateTime.t()
    moon node_type :: atom()
  end
end

defplanet GraphEdge do
  orbitals do
    moon id :: String.t()
    moon from_node :: String.t()
    moon to_node :: String.t()
    moon weight :: float()
    moon frequency :: float()
    moon relationship_type :: atom()
    moon properties :: map()
    moon created_at :: DateTime.t()
    moon relationship_strength :: float()
  end
end

defstar WeightedGraph do
  layers do
    core EmptyGraph
    core SingleNode,
      node :: GraphNode.t()
    core ConnectedGraph,
      nodes :: [GraphNode.t()],
      edges :: [GraphEdge.t()],
      topology_type :: atom()
    core ClusteredGraph,
      clusters :: [GraphCluster.t()],
      inter_cluster_edges :: [GraphEdge.t()],
      clustering_algorithm :: atom()
    core HierarchicalGraph,
      root :: GraphNode.t(),
      children :: [asteroid(WeightedGraph)], # NOTE: "astroid" here declares a core layer property as recursive
      hierarchy_type :: atom()
  end
end

defplanet GraphCluster do
  orbitals do
    moon id :: String.t()
    moon nodes :: [GraphNode.t()]
    moon internal_edges :: [GraphEdge.t()]
    moon cluster_type :: atom()
    moon cohesion_score :: float()
  end
end

defstar Result do
  layers do
    core Success,
      value :: any()
    core Error,
      message :: String.t(),
      code :: integer()
  end
end

result = %{__star__: :Success, value: %{data: "data"}}
test1 = fission Result, result do
  core Success, value: %{data: data}} -> "Got: #{data}"
  core Error, message: _message, code: code} -> "Error #{code}"
end

continue = :success
test2 = fusion Result, continue do
  :success -> core Success, value: "operation completed"
  :error -> core Error, message: "operation failed"
end
