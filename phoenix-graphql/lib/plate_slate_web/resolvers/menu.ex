defmodule PlateSlateWeb.Resolvers.Menu do
  alias PlateSlate.Menu

  # If we would use batch way to load categories of menu_items.
  #import Absinthe.Resolution.Helpers, only: [batch: 3]

  # Using Dataloader way for loading categories of menu_items, which is more recommended
  import Absinthe.Resolution.Helpers, only: [on_load: 2]

  def get_item(_, %{id: id}, %{context: %{loader: loader}}) do
    {:ok, Menu.get_item!(id)}

    #!!!! by tutorial way, but this doesn't return anything. Have to investigate it better.
    #loader
    #|> Dataloader.load(Menu, Menu.Item, id)
    #|> on_load(fn loader ->
      #IO.puts "**************************"
      #IO.puts "**************************"
      #IO.inspect(Dataloader.get(loader, Menu, Menu.Item, id))
      #IO.inspect(loader)
      #IO.puts "**************************"
      #IO.puts "**************************"
      #{:ok, Dataloader.get(loader, Menu, Menu.Item, id)}
    #end)
  end

  def menu_items(_, args, _) do
    {:ok, Menu.list_items(args)}
  end

  def categories(_, args, _) do
    {:ok, Menu.list_categories(args)}
  end

  def items_for_category(category, args, %{context: %{loader: loader}}) do
    loader
    |> Dataloader.load(Menu, {:items, args}, category)
    |> on_load(fn loader ->
      items = Dataloader.get(loader, Menu, {:items, args}, category)
      {:ok, items}
    end)
  end

  def category_for_item(menu_item, _, %{context: %{loader: loader}}) do
  #def category_for_item(menu_item, _, _) do
    # Batch fn takes 3 params.
    # 1st - tuple of module and function which will be execute the batch query
    # 2nd - value to be aggregated
    # 3rd - function for getting result for specific field (item's category in this case)
    #batch({PlateSlate.Menu, :categories_by_id}, menu_item.category_id, fn
      #categories ->
        #{:ok, Map.get(categories, menu_item.category_id)}
    #end) |> IO.inspect
    loader
    |> Dataloader.load(Menu, :category, menu_item)
    # on_load callback is called after Dataloader batches have beed run.
    |> on_load(fn loader ->
      category = Dataloader.get(loader, Menu, :category, menu_item)
      {:ok, category}
    end)
  end

  def search(_, %{matching: term}, _) do
    {:ok, Menu.search(term)}
  end

  def create_item(_, %{input: params}, _) do
    Menu.create_item(params) |> handle_mutation
  end

  def update_item(_, %{input: params, id: id}, _) do
    Menu.get_item!(id)
    |> Menu.update_item(params)
    |> handle_mutation
  end

  defp handle_mutation(ecto_result) do
    with {:ok, item} <- ecto_result do
      {:ok, %{menu_item: item}}
    end
  end
end
