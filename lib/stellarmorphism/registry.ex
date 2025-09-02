defmodule Stellarmorphism.Registry do
  @moduledoc false

  # Persistent registry for planets and stars
  @pt_planets {:stellarmorphism, :planets}
  @pt_stars {:stellarmorphism, :stars}
  @pt_star_variants {:stellarmorphism, :star_variants}
  
  # Phase 1: Persistent registry for parameterized types
  @pt_parameterized_planets {:stellarmorphism, :parameterized_planets}
  @pt_parameterized_stars {:stellarmorphism, :parameterized_stars}
  @pt_type_instances {:stellarmorphism, :type_instances}

  def register_planet(module, orbitals) when is_atom(module) and is_list(orbitals) do
    update_pt(@pt_planets, fn map -> Map.put(map, module, %{orbitals: orbitals}) end)
    :ok
  end

  def register_star(module, variants) when is_atom(module) and is_list(variants) do
    update_pt(@pt_stars, fn map -> Map.put(map, module, Map.new(variants)) end)

    # Also index by variant name for quick lookup during macro transforms
    update_pt(@pt_star_variants, fn map ->
      Enum.reduce(variants, map, fn {variant, orbitals}, acc ->
        Map.update(acc, variant, %{module: module, orbitals: orbitals}, fn _ ->
          %{module: module, orbitals: orbitals}
        end)
      end)
    end)

    :ok
  end

  def get_planet(module) when is_atom(module) do
    :persistent_term.get(@pt_planets, %{}) |> Map.get(module)
  end

  def get_star(module) when is_atom(module) do
    :persistent_term.get(@pt_stars, %{}) |> Map.get(module)
  end

  def get_star_variant(variant) when is_atom(variant) do
    :persistent_term.get(@pt_star_variants, %{}) |> Map.get(variant)
  end

  # -----------------------------
  # Phase 1: Parameterized type registration
  # -----------------------------
  
  def register_parameterized_planet(module, orbitals, type_params, defaults) 
      when is_atom(module) and is_list(orbitals) and is_list(type_params) do
    update_pt(@pt_parameterized_planets, fn map -> 
      Map.put(map, module, %{
        orbitals: orbitals,
        type_params: type_params,
        defaults: defaults
      })
    end)
    :ok
  end

  def register_parameterized_star(module, variants, type_params, defaults) 
      when is_atom(module) and is_list(variants) and is_list(type_params) do
    update_pt(@pt_parameterized_stars, fn map -> 
      Map.put(map, module, %{
        variants: Map.new(variants),
        type_params: type_params,
        defaults: defaults
      })
    end)
    
    # Also index by variant name for parameterized stars
    update_pt(@pt_star_variants, fn map ->
      Enum.reduce(variants, map, fn {variant, orbitals}, acc ->
        Map.update(acc, variant, %{
          module: module, 
          orbitals: orbitals, 
          parameterized: true,
          type_params: type_params
        }, fn existing ->
          # Handle variant name collisions by storing multiple modules
          existing_modules = case existing do
            %{modules: modules} -> modules
            %{module: single_module} -> [single_module]
          end
          
          %{
            modules: [module | existing_modules],
            orbitals: orbitals,
            parameterized: true,
            type_params: type_params
          }
        end)
      end)
    end)
    
    :ok
  end

  def register_type_instance(base_module, param_values, instance_data) 
      when is_atom(base_module) and is_map(param_values) do
    instance_key = {base_module, param_values}
    update_pt(@pt_type_instances, fn map -> 
      Map.put(map, instance_key, instance_data)
    end)
    :ok
  end

  # -----------------------------
  # Phase 1: Parameterized type retrieval
  # -----------------------------
  
  def get_parameterized_planet(module) when is_atom(module) do
    :persistent_term.get(@pt_parameterized_planets, %{}) |> Map.get(module)
  end

  def get_parameterized_star(module) when is_atom(module) do
    :persistent_term.get(@pt_parameterized_stars, %{}) |> Map.get(module)
  end

  def get_type_instance(base_module, param_values) 
      when is_atom(base_module) and is_map(param_values) do
    instance_key = {base_module, param_values}
    :persistent_term.get(@pt_type_instances, %{}) |> Map.get(instance_key)
  end

  def list_parameterized_planets do
    :persistent_term.get(@pt_parameterized_planets, %{}) |> Map.keys()
  end

  def list_parameterized_stars do
    :persistent_term.get(@pt_parameterized_stars, %{}) |> Map.keys()
  end

  # Check if a module is parameterized
  def is_parameterized?(module) when is_atom(module) do
    has_parameterized_planet = Map.has_key?(
      :persistent_term.get(@pt_parameterized_planets, %{}), 
      module
    )
    has_parameterized_star = Map.has_key?(
      :persistent_term.get(@pt_parameterized_stars, %{}), 
      module
    )
    
    has_parameterized_planet or has_parameterized_star
  end

  # Get type parameters for a module
  def get_type_params(module) when is_atom(module) do
    case get_parameterized_planet(module) do
      %{type_params: params} -> params
      nil ->
        case get_parameterized_star(module) do
          %{type_params: params} -> params
          nil -> []
        end
    end
  end

  defp update_pt(key, fun) do
    current = :persistent_term.get(key, %{})
    :persistent_term.put(key, fun.(current))
  end
end
