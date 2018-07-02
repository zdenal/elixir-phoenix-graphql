#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlateWeb.Schema.Query.MenuItemsTest do
  use PlateSlateWeb.ConnCase, async: true

  setup do
    PlateSlate.Seeds.run()
  end

  @query """
  {
    menuItems {
      name
    }
  }
  """
  test "menuItems field returns menu items" do
    conn = get build_conn(), "/api", query: @query
    assert "Water" == json_response(conn, 200)["data"]["menuItems"] |> List.last |> Map.get("name")
  end

  @query """
  query($order: SortOrder!) {
    menuItems(order: $order) {
      name
    }
  }
  """
  @variables %{"order" => "DESC"}
  test "menuItems field returns menu items in DESC" do
    conn = get build_conn(), "/api", query: @query, variables: @variables
    assert "Water" == json_response(conn, 200)["data"]["menuItems"] |> List.first |> Map.get("name")
  end

  @query """
  query($filter: MenuItemFilter!) {
    menuItems(filter: $filter) {
      name
    }
  }
  """
  @variables %{"filter": %{"name" => "reu"}}
  test "filter by name" do
    conn = get build_conn(), "/api", query: @query, variables: @variables
    assert 1 == json_response(conn, 200)["data"]["menuItems"] |> Enum.count
  end

  @query """
  query($filter: MenuItemFilter!) {
    menuItems(filter: $filter) {
      name
    }
  }
  """
  @variables %{"filter": %{"tag" => "Vegetarian", "category" => "Sandwiches"}}
  test "filter by tag and category" do
    conn = get build_conn(), "/api", query: @query, variables: @variables

    assert 1 == json_response(conn, 200)["data"]["menuItems"] |> Enum.count
    assert "Vada Pav" == json_response(conn, 200)["data"]["menuItems"] |> List.first |> Map.get("name")
  end

  @query """
  query($filter: MenuItemFilter!) {
    menuItems(filter: $filter) {
      name
    }
  }
  """
  @variables %{"filter": %{"name" => 123}}
  test "return error when using bad value" do
    conn = get build_conn(), "/api", query: @query, variables: @variables
    assert "Argument \"filter\" has invalid value $filter.\nIn field \"name\": Expected type \"String\", found 123." == json_response(conn, 400)["errors"] |> List.first |> Map.get("message")
  end

end
