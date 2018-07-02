defmodule PlateSlateWeb.Schema.Query.CreateMenuItemTest do
  use PlateSlateWeb.ConnCase, async: true

  alias PlateSlate.{Repo, Menu}
  import Ecto.Query

  defp auth_user(conn, user) do
    token = PlateSlateWeb.Authentication.sign(%{role: user.role, id: user.id})
    put_req_header(conn, "authorization", "Bearer #{token}")
  end

  setup do
    PlateSlate.Seeds.run()

    category_id =
      from(t in Menu.Category, where: t.name == "Sandwiches")
      |> Repo.one!
      |> Map.fetch!(:id)
      |> to_string

    conn = build_conn() |> auth_user(Factory.create_user("employee"))

    {:ok, category_id: category_id, conn: conn}
  end

  @query """
  mutation ($input: MenuItemInput!) {
    createMenuItem(input: $input) {
      errors { key message }
      menuItem {
        name
        description
        price
      }
    }
  }
  """
  test "create Menu Item", %{category_id: category_id, conn: conn} do
    item = %{"name" => "French Dip", "description" => "Descritpion of french dip.", "price" => "5.75", "category_id" => category_id}

    conn = post conn, "/api", query: @query, variables: %{input: item}

    assert %{"data" => %{"createMenuItem" => %{"menuItem" => result}}} = json_response(conn, 200)
    assert result == %{
      "name" => item["name"],
      "description" => item["description"],
      "price" => item["price"],
    }
  end

  @query """
  mutation ($input: MenuItemInput!) {
    createMenuItem(input: $input) {
      errors { key message }
      menuItem {
        name
        description
        price
      }
    }
  }
  """
  test "create with already existing name -> fails", %{category_id: category_id, conn: conn} do
    item = %{"name" => "Reuben", "description" => "Desc.", "price" => "5.75", "category_id" => category_id}

    conn = post conn, "/api", query: @query, variables: %{input: item}

    assert %{"data" => %{"createMenuItem" => %{"menuItem" => nil, "errors" => errors}}} = json_response(conn, 200)
    assert "has already been taken" == errors |> List.first |> Map.get("message")
  end

  @query """
  mutation ($input: MenuItemInput!, $id: ID) {
    updateMenuItem(input: $input, id: $id) {
      errors { key message }
      menuItem {
        id
        name
        description
        price
      }
    }
  }
  """
  test "update Menu Item", %{category_id: category_id, conn: conn} do
    input = %{"name" => "New Name", "description" => "Desc.", "price" => "5.75", "category_id" => category_id}
    item = Menu.Item |> first |> Repo.one

    conn = post conn, "/api", query: @query, variables: %{input: input, id: item.id}

    assert %{"data" => %{"updateMenuItem" => %{"menuItem" => result, "errors" => nil}}} = json_response(conn, 200)
    assert "New Name" == result["name"]
    assert to_string(item.id) == result["id"]
  end
end
