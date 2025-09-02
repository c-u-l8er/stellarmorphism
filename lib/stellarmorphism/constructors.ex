defmodule Stellarmorphism.Constructors do
  @moduledoc """
  Phase 1: Enhanced constructor logic for Stellarmorphism.
  
  Provides support for:
  - Parameterized constructors with runtime arguments
  - Default value resolution using type parameters
  - Enhanced fusion/fission with parameter passing
  - Constructor function generation
  """

  alias Stellarmorphism.Types

  # -----------------------------
  # Constructor generation
  # -----------------------------
  @doc """
  Generates enhanced constructor functions for parameterized types.
  
  Creates both `new/N` functions for direct construction and builder
  functions for use with fusion.
  """
  def generate_constructors(module_name, params, _orbitals, defaults) do
    quote do
      # Generate the main constructor
      unquote(Types.generate_constructor(module_name, params, defaults))
      
      # Generate builder function for fusion compatibility
      unquote(generate_builder(module_name, params, defaults))
      
      # Generate parameter info function
      @doc false
      def __stellarmorphism__(:params), do: unquote(Macro.escape(params))
      
      @doc false
      def __stellarmorphism__(:defaults), do: unquote(Macro.escape(defaults))
    end
  end

  defp generate_builder(_module_name, params, _defaults) do
    param_names = Enum.map(params, fn {name, _constraint} -> name end)
    
    quote do
      @doc """
      Builds an instance with the given parameters and attributes.
      
      Used internally by fusion expressions and other DSL constructs.
      """
      def build(unquote_splicing(param_vars(param_names)), attrs) do
        new(unquote_splicing(param_vars(param_names)), attrs)
      end
    end
  end

  defp param_vars(param_names) do
    Enum.map(param_names, fn name ->
      {name, [], nil}
    end)
  end

  # -----------------------------
  # Enhanced core construction
  # -----------------------------
  @doc """
  Transforms core constructors to handle parameterized types and defaults.
  
  Extends the basic core syntax to support:
  - Type parameters: Container.new(String, 10, %{items: [...]})
  - Default resolution: capacity gets max_size value automatically
  - Recursive types: asteroid(...) and rocket(...) expressions
  """
  def transform_enhanced_core({:core, meta, [variant_ast | field_specs]}, star_type, type_params, _caller) do
    # Extract variant name
    variant_name = extract_variant_name(variant_ast)
    
    # Process field specifications with parameter support
    enhanced_fields = process_field_specs(field_specs, type_params)
    
    # Generate constructor expression
    quote do
      %{__star__: unquote(variant_name)} 
      |> Map.merge(unquote({:%{}, meta, enhanced_fields}))
      |> apply_type_defaults(unquote(star_type), unquote(type_params))
    end
  end

  defp extract_variant_name({:__aliases__, _, [name]}), do: name
  defp extract_variant_name(name) when is_atom(name), do: name
  defp extract_variant_name(_), do: :unknown_variant

  defp process_field_specs(field_specs, type_params) do
    flat_specs = case field_specs do
      [[_ | _] = keyword_list] -> keyword_list
      keyword_list when is_list(keyword_list) -> keyword_list
      _ -> field_specs
    end
    
    Enum.map(flat_specs, fn
      # Handle asteroid expressions: left: asteroid(...)
      {field, {:asteroid, expr}} when is_atom(field) ->
        {field, transform_asteroid_expr(expr, type_params)}
      
      # Handle rocket expressions: tail: rocket(...)
      {field, {:rocket, expr}} when is_atom(field) ->
        {field, transform_rocket_expr(expr, type_params)}
      
      # Handle parameter references: capacity: max_size
      {field, param_ref} when is_atom(field) and is_atom(param_ref) ->
        if param_ref in (type_params |> Enum.map(fn {name, _} -> name end)) do
          {field, {:param_ref, param_ref}}
        else
          {field, param_ref}
        end
      
      # Handle regular field assignments
      {field, value} when is_atom(field) ->
        {field, value}
      
      other ->
        other
    end)
  end

  defp transform_asteroid_expr(expr, _type_params) do
    quote do
      Stellarmorphism.Recursion.asteroid(unquote(expr))
    end
  end

  defp transform_rocket_expr(expr, _type_params) do
    quote do
      Stellarmorphism.Recursion.rocket(unquote(expr))
    end
  end

  # -----------------------------
  # Default value application
  # -----------------------------
  @doc """
  Applies type parameter defaults to constructed values.
  
  Resolves parameter references and applies default values based on
  the type definition and runtime parameter values.
  """
  def apply_type_defaults(value, star_type, type_params) when is_map(value) do
    # Get default mappings from the star type if available
    defaults = get_star_defaults(star_type)
    param_values = Map.new(type_params)
    
    # Resolve parameter references and defaults
    resolved_value = Map.new(value, fn
      {key, {:param_ref, param_name}} ->
        {key, Map.get(param_values, param_name)}
      
      {key, val} ->
        {key, val}
    end)
    
    # Apply defaults for missing fields
    apply_defaults_to_map(resolved_value, defaults, param_values)
  end
  
  def apply_type_defaults(value, _star_type, _type_params), do: value

  defp get_star_defaults(star_type) do
    try do
      if function_exported?(star_type, :__stellarmorphism__, 1) do
        star_type.__stellarmorphism__(:defaults)
      else
        %{}
      end
    rescue
      _ -> %{}
    end
  end

  defp apply_defaults_to_map(value, defaults, param_values) do
    Enum.reduce(defaults, value, fn {field, default_spec}, acc ->
      if Map.has_key?(acc, field) do
        acc
      else
        default_value = resolve_default_value(default_spec, param_values)
        Map.put(acc, field, default_value)
      end
    end)
  end

  defp resolve_default_value({:default, param_name}, param_values) do
    Map.get(param_values, param_name)
  end
  
  defp resolve_default_value(value, _param_values), do: value

  # -----------------------------
  # Fusion/Fission enhancement
  # -----------------------------
  @doc """
  Enhances fusion expressions to support parameterized constructors.
  
  Allows fusion clauses to create parameterized types with runtime values.
  """
  def enhance_fusion_clause({:->, meta, [patterns, body]}, star_type, type_params) do
    enhanced_body = enhance_constructor_body(body, star_type, type_params)
    {:->, meta, [patterns, enhanced_body]}
  end

  defp enhance_constructor_body({:core, _meta, _args} = core_expr, star_type, type_params) do
    transform_enhanced_core(core_expr, star_type, type_params, nil)
  end
  
  defp enhance_constructor_body(other, _star_type, _type_params), do: other

  # -----------------------------
  # Utility functions
  # -----------------------------
  @doc """
  Extracts default field specifications from orbital definitions.
  
  Parses orbital definitions to find default value specifications.
  """
  def extract_defaults(orbitals) do
    Enum.reduce(orbitals, %{}, fn
      {name, _type, opts}, acc ->
        case Keyword.get(opts, :default) do
          nil -> acc
          default_value -> Map.put(acc, name, default_value)
        end
      
      _, acc -> acc
    end)
  end

  @doc """
  Validates constructor arguments against type constraints.
  
  Used during runtime construction to ensure type safety.
  """
  def validate_constructor_args(args, constraints) do
    case Types.validate_constraints(args, constraints) do
      :ok -> :ok
      {:error, msg} -> raise ArgumentError, "Constructor validation failed: #{msg}"
    end
  end

  @doc """
  Builds parameter list for constructor function signatures.
  
  Creates the appropriate parameter list based on type parameters.
  """
  def build_param_signature(type_params) do
    Enum.map(type_params, fn {name, _constraint} ->
      {name, [], nil}
    end)
  end
end
