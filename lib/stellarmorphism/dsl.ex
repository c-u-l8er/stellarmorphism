defmodule Stellarmorphism.DSL do
  @moduledoc """
  Core DSL for Stellarmorphism Phase 0:

  - `defplanet Name do ... end` with `orbitals do ... end` and `moon/1-2`
  - `defstar Name do ... end` with `layers do ... end` and `core/2`
  - `fission StarType, value do ... end` for type-safe pattern matching
  - `fusion StarType, seed do ... end` for type-safe construction
  - `asteroid/0,1` helper for recursive identifiers
  """

  # -----------------------------
  # Planet (product) definitions
  # -----------------------------
  defmacro defplanet(name_ast, do: block) do
    # Get the current module context and create the full module name
    caller_module = __CALLER__.module
    mod = case name_ast do
      {:__aliases__, _, parts} when length(parts) == 1 ->
        # Single part alias like TestUser should be relative to caller module
        Module.concat([caller_module | parts])
      {:__aliases__, _, parts} ->
        # Multi-part alias like My.Module.TestUser should be absolute
        Module.concat(parts)
      atom when is_atom(atom) ->
        Module.concat([caller_module, atom])
    end

    # Extract orbital definitions from the block at compile time
    orbitals = extract_orbitals_from_block(block)
    orbital_names = Enum.map(orbitals, fn {name, _type, _opts} -> name end)

    quote do
      defmodule unquote(mod) do
        # Define the struct with the extracted orbital names
        defstruct unquote(orbital_names)

        @doc false
        def __stellarmorphism__(:orbitals), do: unquote(orbital_names)

        @doc false
        @spec new(map()) :: struct()
        def new(attrs \\ %{}) do
          struct!(__MODULE__, attrs)
        end
      end

      # Register planet metadata for compile-time transforms
      Stellarmorphism.Registry.register_planet(
        unquote(mod),
        unquote(orbital_names)
      )
    end
  end

  defp extract_orbitals_from_block(block) do
    case block do
      {:orbitals, _, [[do: orbital_block]]} ->
        extract_orbitals_from_ast(orbital_block)
      _ ->
        []
    end
  end

  defp extract_orbitals_from_ast({:__block__, _, statements}) do
    Enum.flat_map(statements, &extract_orbital_from_statement/1)
  end
  defp extract_orbitals_from_ast(single_statement) do
    extract_orbital_from_statement(single_statement)
  end

  defp extract_orbital_from_statement({:orbital, _, [name]}) do
    [{name, :any, []}]
  end
  defp extract_orbital_from_statement({:orbital, _, [name, type]}) do
    [{name, type, []}]
  end
  defp extract_orbital_from_statement({:orbital, _, [name, type, opts]}) do
    [{name, type, opts}]
  end
  defp extract_orbital_from_statement({:moon, _, [{:"::", _, [name, type]}]}) do
    # Support stellar syntax: moon name :: Type.t()
    orbital_name = case name do
      {name_atom, _, nil} when is_atom(name_atom) -> name_atom  # Variable reference like `id`
      name_atom when is_atom(name_atom) -> name_atom            # Direct atom like `:id`
      _ -> :unknown_field
    end
    [{orbital_name, type, []}]
  end
  defp extract_orbital_from_statement({:moon, _, [name]}) do
    # Support stellar syntax: moon name
    orbital_name = case name do
      {name_atom, _, nil} when is_atom(name_atom) -> name_atom  # Variable reference like `id`
      name_atom when is_atom(name_atom) -> name_atom            # Direct atom like `:id`
      _ -> :unknown_field
    end
    [{orbital_name, :any, []}]
  end
  defp extract_orbital_from_statement({:"::", _, [name, type]}) do
    # Support Enhanced ADT style: name :: Type.t()
    orbital_name = case name do
      {name_atom, _, nil} when is_atom(name_atom) -> name_atom  # Variable reference like `id`
      name_atom when is_atom(name_atom) -> name_atom            # Direct atom like `:id`
      _ -> :unknown_field
    end
    [{orbital_name, type, []}]
  end
  defp extract_orbital_from_statement(name) when is_atom(name) do
    # Support bare field names
    [{name, :any, []}]
  end
  defp extract_orbital_from_statement(_) do
    []
  end

  defmacro orbitals(do: block), do: block
  defmacro layers(do: block), do: block

  # Orbital macros are now no-ops since we extract at compile time
  defmacro orbital(_name), do: nil
  defmacro orbital(_name, _type), do: nil
  defmacro orbital(_name, _type, _opts), do: nil

  # Stellar syntax macros are now no-ops since we extract at compile time
  defmacro moon(_field_spec), do: nil

  # Core macro for pattern matching and construction
  defmacro core(variant_name, field_specs) do
    # Convert core VariantName, field: pattern to %{__star__: :VariantName, field: pattern}
    field_patterns = Enum.map(field_specs, fn
      {field, pattern} when is_atom(field) -> {field, pattern}
      _ -> raise "Invalid core syntax"
    end)
    {:%{}, [], [{:__star__, variant_name} | field_patterns]}
  end

  # -----------------------------
  # Star (sum) definitions
  # -----------------------------
  defmacro defstar(name_ast, do: block) do
    # Get the current module context and create the full module name
    caller_module = __CALLER__.module
    mod = case name_ast do
      {:__aliases__, _, parts} when length(parts) == 1 ->
        # Single part alias like TestNetwork should be relative to caller module
        Module.concat([caller_module | parts])
      {:__aliases__, _, parts} ->
        # Multi-part alias like My.Module.TestNetwork should be absolute
        Module.concat(parts)
      atom when is_atom(atom) ->
        Module.concat([caller_module, atom])
    end

    # Extract variant definitions from the block at compile time
    variants = extract_variants_from_block(block)
    variants_map = Map.new(variants)

    quote do
      defmodule unquote(mod) do
        @doc false
        def __stellarmorphism__(:variants), do: unquote(Macro.escape(variants_map))
      end

      Stellarmorphism.Registry.register_star(
        unquote(mod),
        unquote(variants)
      )
    end
  end

  defp extract_variants_from_block({:__block__, _, statements}) do
    Enum.flat_map(statements, &extract_variant_from_statement/1)
  end
  defp extract_variants_from_block(single_statement) do
    extract_variant_from_statement(single_statement)
  end

  # Support stellar layers syntax: layers do ... end
  defp extract_variant_from_statement({:layers, _, [[do: layers_block]]}) do
    extract_variants_from_layers(layers_block)
  end
  defp extract_variant_from_statement({:variant, _, [variant_name, [do: variant_block]]}) do
    orbitals = extract_orbitals_from_ast(variant_block)
    orbital_names = Enum.map(orbitals, fn {name, _type, _opts} -> name end)
    [{variant_name, orbital_names}]
  end
  defp extract_variant_from_statement(_) do
    []
  end

  defp extract_variants_from_layers({:__block__, _, statements}) do
    Enum.flat_map(statements, &extract_core_variant/1)
  end
  defp extract_variants_from_layers(single_statement) do
    extract_core_variant(single_statement)
  end

  # Support stellar core syntax with alias and typed fields: core Connected, primary :: User.t(), connections :: [Connection.t()]
  defp extract_core_variant({:core, _, [variant_ast | field_specs]}) when length(field_specs) > 0 do
    # Extract variant name from alias or atom
    variant_name = case variant_ast do
      {:__aliases__, _, [name]} -> name
      name when is_atom(name) -> name
      _ -> :unknown_variant
    end

    orbital_names = Enum.flat_map(field_specs, fn
      {:"::", _, [{name, _, nil}, _type]} when is_atom(name) -> [name]  # primary :: User.t()
      {:"::", _, [name, _type]} when is_atom(name) -> [name]            # name :: Type.t()
      {name, _type} when is_atom(name) -> [name]                        # name: value
      name when is_atom(name) -> [name]                                 # bare name
      _ -> []
    end)
    [{variant_name, orbital_names}]
  end
  # Support simple core variants: core EmptyGraph
  defp extract_core_variant({:core, _, [variant_name]}) when is_atom(variant_name) do
    [{variant_name, []}]
  end
  defp extract_core_variant(_) do
    []
  end

  # Variant macro is now a no-op since we extract at compile time
  defmacro variant(_variant_name, do: _block), do: nil

  # -----------------------------
  # Phase 0: Star-Prefixed Fission (pattern matching)
  # -----------------------------
  defmacro fission(star_type, value, do: clauses) do
    # Validate star_type at compile time if possible
    validate_star_type_at_compile_time(star_type, __CALLER__)

    # Transform core patterns in the clauses to validate against the star type
    transformed_clauses = transform_fission_clauses(clauses, star_type, __CALLER__)

    quote do
      case unquote(value) do
        unquote(transformed_clauses)
      end
    end
  end

  # -----------------------------
  # Phase 0: Star-Prefixed Fusion (construction)
  # -----------------------------
  defmacro fusion(star_type, seed, do: clauses) do
    # Validate star_type at compile time if possible
    validate_star_type_at_compile_time(star_type, __CALLER__)

    # Transform core constructors in the clauses to validate against the star type
    transformed_clauses = transform_fusion_clauses(clauses, star_type, __CALLER__)

    quote do
      case unquote(seed) do
        unquote(transformed_clauses)
      end
    end
  end

  # -----------------------------
  # Asteroid (recursive/identifier helper)
  # -----------------------------
  defmacro asteroid(name \\ nil) do
    quote bind_quoted: [name: name] do
      id = Base.encode16(:crypto.strong_rand_bytes(8)) |> String.downcase()
      {:asteroid, name || String.to_atom("a_" <> id), id}
    end
  end

  # -----------------------------
  # Phase 0: Compile-time validation functions
  # -----------------------------

  defp validate_star_type_at_compile_time(star_type_ast, caller) do
    # Extract the star type module from the AST
    star_module = case star_type_ast do
      {:__aliases__, _, parts} ->
        # Handle qualified module names like TestTypes.Result
        case parts do
          [single_part] when caller.module != nil ->
            # Single part could be relative to caller module
            Module.concat([caller.module, single_part])
          _ ->
            # Multi-part is absolute
            Module.concat(parts)
        end
      atom when is_atom(atom) ->
        # Handle unqualified atoms - they should be relative to caller module
        Module.concat([caller.module, atom])
      _ ->
        nil
    end

    # Note: At compile-time, the star might not be registered yet due to compilation order
    # We'll do basic validation here and leave runtime validation for the actual matching
    if star_module do
      :ok
    else
      raise CompileError,
        file: caller.file,
        line: caller.line,
        description: "Invalid star type specification: #{inspect(star_type_ast)}"
    end
  end

  defp validate_core_against_star_type(variant_name, star_type_ast, caller) do
    # This is a placeholder for future compile-time core validation
    # For now, we'll rely on runtime pattern matching to catch invalid cores
    :ok
  end

  # -----------------------------
  # Internal transformation functions (Phase 0 Updated)
  # -----------------------------

  # Transform fission clauses to convert core patterns to map patterns with validation
  defp transform_fission_clauses({:__block__, meta, clauses}, star_type, caller) do
    {:__block__, meta, Enum.map(clauses, &transform_fission_clause(&1, star_type, caller))}
  end
  defp transform_fission_clauses([{:->, _, _} | _] = clauses, star_type, caller) do
    Enum.map(clauses, &transform_fission_clause(&1, star_type, caller))
  end
  defp transform_fission_clauses(single_clause, star_type, caller), do: transform_fission_clause(single_clause, star_type, caller)

  defp transform_fission_clause({:->, meta, [patterns, body]}, star_type, caller) do
    transformed_patterns = Enum.map(patterns, &transform_core_pattern(&1, star_type, caller))
    {:->, meta, [transformed_patterns, body]}
  end

  # Transform fusion clauses to convert core constructors to map constructors with validation
  defp transform_fusion_clauses({:__block__, meta, clauses}, star_type, caller) do
    {:__block__, meta, Enum.map(clauses, &transform_fusion_clause(&1, star_type, caller))}
  end
  defp transform_fusion_clauses([{:->, _, _} | _] = clauses, star_type, caller) do
    Enum.map(clauses, &transform_fusion_clause(&1, star_type, caller))
  end
  defp transform_fusion_clauses(single_clause, star_type, caller), do: transform_fusion_clause(single_clause, star_type, caller)

  defp transform_fusion_clause({:->, meta, [patterns, body]}, star_type, caller) do
    transformed_patterns = Enum.map(patterns, &transform_core_pattern(&1, star_type, caller))
    transformed_body = transform_core_constructor(body, star_type, caller)
    {:->, meta, [transformed_patterns, transformed_body]}
  end

  # Transform core patterns with star type validation: core VariantName, field: pattern -> %{__star__: :VariantName, field: pattern}
  defp transform_core_pattern({:core, meta, [variant_ast | field_specs]}, star_type, caller) do
    # Extract variant name from alias or atom
    variant_name = case variant_ast do
      {:__aliases__, _, [name]} -> name
      name when is_atom(name) -> name
      _ -> raise CompileError,
        file: caller.file,
        line: caller.line,
        description: "Invalid variant name in core pattern: #{inspect(variant_ast)}"
    end

    # Validate that this variant belongs to the specified star type
    validate_core_against_star_type(variant_name, star_type, caller)

    # Flatten field_specs if it's nested (which it usually is)
    flat_field_specs = case field_specs do
      [[_ | _] = keyword_list] -> keyword_list  # Single nested list
      keyword_list when is_list(keyword_list) -> keyword_list  # Already flat
      _ -> field_specs
    end

    field_patterns = Enum.map(flat_field_specs, fn
      {field, pattern} when is_atom(field) -> {field, pattern}
      _ -> raise CompileError,
        file: caller.file,
        line: caller.line,
        description: "Invalid core pattern syntax in field specification"
    end)
    {:%{}, meta, [{:__star__, variant_name} | field_patterns]}
  end
  defp transform_core_pattern(other, _star_type, _caller), do: other

  # Transform core constructors with star type validation: core VariantName, field: value -> %{__star__: :VariantName, field: value}
  defp transform_core_constructor({:core, meta, [variant_ast | field_specs]}, star_type, caller) do
    # Extract variant name from alias or atom
    variant_name = case variant_ast do
      {:__aliases__, _, [name]} -> name
      name when is_atom(name) -> name
      _ -> raise CompileError,
        file: caller.file,
        line: caller.line,
        description: "Invalid variant name in core constructor: #{inspect(variant_ast)}"
    end

    # Validate that this variant belongs to the specified star type
    validate_core_against_star_type(variant_name, star_type, caller)

    # Flatten field_specs if it's nested (which it usually is)
    flat_field_specs = case field_specs do
      [[_ | _] = keyword_list] -> keyword_list  # Single nested list
      keyword_list when is_list(keyword_list) -> keyword_list  # Already flat
      _ -> field_specs
    end

    field_assignments = Enum.map(flat_field_specs, fn
      {field, value} when is_atom(field) -> {field, value}
      other ->
        raise CompileError,
          file: caller.file,
          line: caller.line,
          description: "Invalid core constructor syntax: #{inspect(other)}"
    end)
    {:%{}, meta, [{:__star__, variant_name} | field_assignments]}
  end
  defp transform_core_constructor(other, _star_type, _caller), do: other
end
