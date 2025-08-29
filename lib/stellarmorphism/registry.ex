defmodule Stellarmorphism.Registry do
  @moduledoc false

  # Persistent registry for planets and stars
  @pt_planets {:stellarmorphism, :planets}
  @pt_stars {:stellarmorphism, :stars}
  @pt_star_variants {:stellarmorphism, :star_variants}

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

  defp update_pt(key, fun) do
    current = :persistent_term.get(key, %{})
    :persistent_term.put(key, fun.(current))
  end
end
