defmodule PlateSlateWeb.ItemController do
  use PlateSlateWeb, :controller

  use Absinthe.Phoenix.Controller,
    schema: PlateSlateWeb.Schema,
    action: [mode: :internal]

    # The @action directive returns regular Elixir structs (eg. `%PlateSlate.Menu.Item`)
    # and not json (Map). This is what resolvers are returning. You can use `@action` directly
    # in query (as used for method `index`) or use it as default for controller (above) and
    # then you don't need to specify it (as you can see for `show` method).
    #
    # The @put struct is returning correctly Elixir association structs. For this
    # server side app purposes we can't use queries which is eg. returning
    # only `name` as Elixir templates and helpers (eg. `item_path(@conn, :show, item)`) are dependent
    # on Elixir structs, which for example are containg always id and so on.
  @graphql """
  query Index @action(mode: INTERNAL) {
    menu_items @put {
      category
      order_history {
        quantity
      }
    }
  }
  """
  def index(conn, result) do
    render(conn, "index.html", items: result.data.menu_items)
  end

  @graphql """
  query ($id: ID!, $since: Date) {
    menu_item(id: $id) @put {
      order_history(since: $since) {
        quantity
        gross
        orders
      }
    }
  }
  """
  def show(conn, %{data: %{menu_item: nil}}) do
    conn
    |> put_flash(:info, "Menu item not found")
    |> redirect(to: "/admin/items")
  end
  def show(conn, %{data: %{menu_item: item}}) do
    since = variables(conn)["since"] || "2018-01-01"
    render(conn, "show.html", item: item, since: since)
  end
end
