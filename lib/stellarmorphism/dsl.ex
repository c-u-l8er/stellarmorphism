defmodule Stellarmorphism.DSL do
  @moduledoc """
  Core DSL for Stellarmorphism Phase 0 + Phase 1:

  Phase 0 Features:
  - `defplanet Name do ... end` with `orbitals do ... end` and `moon/1-2`
  - `defstar Name do ... end` with `layers do ... end` and `core/2`
  - `fission StarType, value do ... end` for type-safe pattern matching
  - `fusion StarType, seed do ... end` for type-safe construction
  - `asteroid/0,1` helper for recursive identifiers

  Phase 1 Features:
  - Parameterized types: `defstar BinaryTree(t) do ... end`
  - Asteroid recursion: `asteroid(BinaryTree(t))` - eager evaluation
  - Rocket recursion: `rocket(LazyStream(t))` - lazy evaluation
  - Enhanced constructors with type parameters and constraints
  - Variable arguments in fusion/fission expressions
  """

  alias Stellarmorphism.{Types, Constructors}

  # -----------------------------
  # Planet (product) definitions
  # -----------------------------
  defmacro defplanet(name_ast, do: block) do
    # Phase 1: Extract type parameters and base module name
    {base_name, type_params} = Types.extract_type_params(name_ast)
    caller_module = __CALLER__.module

    # Create full module name
    mod = case base_name do
      name_parts when is_list(name_parts) ->
        # Handle {:__aliases__, _, parts} case
        case name_parts do
          [single_part] ->
            Module.concat([caller_module, single_part])
          _ ->
            Module.concat(name_parts)
        end
      name when is_atom(name) ->
        Module.concat([caller_module, name])
      _ ->
        Module.concat([caller_module, :UnknownPlanet])
    end

    # Extract orbital definitions from the block at compile time
    orbitals = extract_orbitals_from_block(block)
    orbital_names = Enum.map(orbitals, fn {name, _type, _opts} -> name end)
    defaults = Constructors.extract_defaults(orbitals)

    if type_params == [] do
      # Phase 0: Simple planet without parameters
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
    else
      # Phase 1: Parameterized planet
      quote do
        defmodule unquote(mod) do
          # Define the struct with the extracted orbital names
          defstruct unquote(orbital_names)

          @doc false
          def __stellarmorphism__(:orbitals), do: unquote(orbital_names)

          @doc false
          def __stellarmorphism__(:params), do: unquote(Macro.escape(type_params))

          @doc false
          def __stellarmorphism__(:defaults), do: unquote(Macro.escape(defaults))

          # Generate parameterized constructors
          unquote(Constructors.generate_constructors(mod, type_params, orbitals, defaults))
        end

        # Register parameterized planet metadata
        Stellarmorphism.Registry.register_parameterized_planet(
          unquote(mod),
          unquote(orbital_names),
          unquote(Macro.escape(type_params)),
          unquote(Macro.escape(defaults))
        )
      end
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

    # Phase 1: Check for asteroid/rocket types
    enhanced_type = extract_enhanced_type(type)
    [{orbital_name, enhanced_type, []}]
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

  # Phase 1: Enhanced type extraction for asteroid/rocket recursion
  defp extract_enhanced_type({:asteroid, _, [type_expr]}) do
    {:asteroid, type_expr}
  end

  defp extract_enhanced_type({:rocket, _, [type_expr]}) do
    {:rocket, type_expr}
  end

  defp extract_enhanced_type(type), do: type

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
    # Phase 1: Extract type parameters and base module name
    {base_name, type_params} = Types.extract_type_params(name_ast)
    caller_module = __CALLER__.module

    # Create full module name
    mod = case base_name do
      name_parts when is_list(name_parts) ->
        # Handle {:__aliases__, _, parts} case
        case name_parts do
          [single_part] ->
            Module.concat([caller_module, single_part])
          _ ->
            Module.concat(name_parts)
        end
      name when is_atom(name) ->
        Module.concat([caller_module, name])
      _ ->
        Module.concat([caller_module, :UnknownStar])
    end

    # Extract variant definitions from the block at compile time
    variants = extract_variants_from_block(block)
    variants_map = Map.new(variants)

    # Phase 1: Extract defaults from variant definitions
    variant_defaults = extract_variant_defaults(variants)

    if type_params == [] do
      # Phase 0: Simple star without parameters
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
    else
      # Phase 1: Parameterized star
      quote do
        defmodule unquote(mod) do
          @doc false
          def __stellarmorphism__(:variants), do: unquote(Macro.escape(variants_map))

          @doc false
          def __stellarmorphism__(:params), do: unquote(Macro.escape(type_params))

          @doc false
          def __stellarmorphism__(:defaults), do: unquote(Macro.escape(variant_defaults))

          # Generate parameterized constructors for each variant
          unquote_splicing(generate_variant_constructors(mod, type_params, variants, variant_defaults))
        end

        # Register parameterized star metadata
        Stellarmorphism.Registry.register_parameterized_star(
          unquote(mod),
          unquote(variants),
          unquote(Macro.escape(type_params)),
          unquote(Macro.escape(variant_defaults))
        )
      end
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

  # Phase 1: Extract default values from variant definitions
  defp extract_variant_defaults(variants) do
    Enum.reduce(variants, %{}, fn {variant_name, field_specs}, acc ->
      defaults = extract_field_defaults(field_specs)
      if defaults == %{} do
        acc
      else
        Map.put(acc, variant_name, defaults)
      end
    end)
  end

  defp extract_field_defaults(field_specs) when is_list(field_specs) do
    Enum.reduce(field_specs, %{}, fn _field_name, acc ->
      # For now, we don't extract defaults from field specs
      # This would be enhanced to support field-level defaults
      acc
    end)
  end
  defp extract_field_defaults(_), do: %{}

  # Phase 1: Generate constructors for parameterized star variants
  defp generate_variant_constructors(mod, type_params, variants, defaults) do
    Enum.map(variants, fn {variant_name, field_specs} ->
      generate_variant_constructor(mod, variant_name, field_specs, type_params, defaults)
    end)
  end

  defp generate_variant_constructor(mod, variant_name, field_specs, type_params, defaults) do
    param_names = Enum.map(type_params, fn {name, _constraint} -> name end)
    _field_names = if is_list(field_specs), do: field_specs, else: []

    quote do
      @doc """
      Creates a #{unquote(variant_name)} variant of #{unquote(mod)}.
      """
      def unquote(String.to_atom("new_#{variant_name}"))(unquote_splicing(param_vars(param_names)), attrs \\ %{}) do
        # Validate type parameters
        param_values = unquote(build_param_values(param_names))
        constraints = unquote(Macro.escape(Enum.filter(type_params, fn {_name, constraint} -> constraint != nil end)))

        case Stellarmorphism.Types.validate_constraints(param_values, constraints) do
          :ok ->
            base_map = %{__star__: unquote(variant_name)}
            |> Map.merge(attrs)
            |> apply_variant_defaults(unquote(variant_name), param_values, unquote(Macro.escape(defaults)))

          {:error, msg} ->
            raise ArgumentError, "Type constraint validation failed: #{msg}"
        end
      end
    end
  end

  # Helper to generate parameter variables
  defp param_vars(param_names) do
    Enum.map(param_names, fn name ->
      {name, [], nil}
    end)
  end

  # Helper to build parameter values map
  defp build_param_values(param_names) do
    param_pairs = Enum.map(param_names, fn name ->
      {name, {name, [], nil}}
    end)
    {:%{}, [], param_pairs}
  end

  # Runtime helper for applying variant defaults
  def apply_variant_defaults(base_map, variant_name, param_values, all_defaults) do
    variant_defaults = Map.get(all_defaults, variant_name, %{})
    resolved_defaults = Types.resolve_defaults(variant_defaults, param_values)
    Map.merge(resolved_defaults, base_map)
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
  # Phase 1: Enhanced Recursion Macros
  # -----------------------------

  # Asteroid macro header with default
  defmacro asteroid(arg \\ nil)

  # Phase 0: Legacy asteroid for backward compatibility
  defmacro asteroid(name) when is_atom(name) or is_nil(name) do
    quote bind_quoted: [name: name] do
      id = Base.encode16(:crypto.strong_rand_bytes(8)) |> String.downcase()
      {:asteroid, name || String.to_atom("a_" <> id), id}
    end
  end

  # Phase 1: New asteroid for eager recursion - when it's not an atom/nil
  defmacro asteroid(type_expr) do
    quote do
      # Evaluate expression immediately when asteroid is created
      unquote(type_expr)
    end
  end

  # Phase 1: Rocket for lazy recursion
  defmacro rocket(type_expr) do
    quote do
      case unquote(type_expr) do
        func when is_function(func, 0) ->
          # If it's already a 0-arity function, use it directly
          {:__rocket__, func}
        value ->
          # Otherwise, wrap it in a function
          {:__rocket__, fn -> value end}
      end
    end
  end

  # Phase 1: Launch for evaluating rockets
  defmacro launch(rocket_value) do
    quote do
      case unquote(rocket_value) do
        {:__rocket__, fun} when is_function(fun, 0) -> fun.()
        other -> other  # Not a rocket, return as-is
      end
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

  defp validate_core_against_star_type(_variant_name, _star_type_ast, _caller) do
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
