defmodule PlateSlateWeb.Schema.Query.SearchTest do
  use PlateSlateWeb.ConnCase, async: true

  setup do
    PlateSlate.Seeds.run()
  end

  # If we would use `union` we need to define attrs in this way.
  @query """
  query($term: String!) {
    search(matching: $term) {
      ... on MenuItem { name }
      ... on Category { name }
      __typename
    }
  }
  """
  @variables %{term: "e"}
  test "search returns both types with specified attrs #1 (union example)" do
    conn = get build_conn(), "/api", query: @query, variables: @variables

    assert %{"data" => %{"search" => results}} = json_response(conn, 200)
    assert length(results) > 0

    assert Enum.find(results, &(&1["__typename"] == "Category"))
    assert Enum.find(results, &(&1["__typename"] == "MenuItem"))
  end

  # Thankfully by interface we can ask for common attrs.
  @query """
  query($term: String!) {
    search(matching: $term) {
      name
      __typename
    }
  }
  """
  @variables %{term: "e"}
  test "search returns both types with specified attrs #2 (interface example)" do
    conn = get build_conn(), "/api", query: @query, variables: @variables

    assert %{"data" => %{"search" => results}} = json_response(conn, 200)
    assert length(results) > 0

    assert Enum.find(results, &(&1["__typename"] == "Category"))
    assert Enum.find(results, &(&1["__typename"] == "MenuItem"))
  end
end
