defmodule PlateSlateWeb.Resolvers.Ordering do
  alias PlateSlate.Ordering

  import Absinthe.Resolution.Helpers, only: [batch: 3]

  def order_history(item, args, _) do
    one_month_ago = Date.utc_today |> Date.add(-30)

    args = Map.update(args, :since, one_month_ago, fn date ->
      date || one_month_ago
    end)
    {:ok, %{item: item, args: args}}
  end

  def orders(%{item: item, args: args}, _, _) do
    batch({Ordering, :orders_by_item_name, args}, item.name, fn orders ->
      {:ok, Map.get(orders, item.name, [])}
    end)
  end

  def stat(stat) do
    fn %{item: item, args: args}, _, _ ->
      batch({Ordering, :orders_stats_by_name, args}, item.name, fn results ->
        {:ok, results[item.name][stat] || 0}
      end)
    end
  end

  def place_order(_, %{input: input}, %{context: context}) do
    input = case context[:current_user] do
      %{role: "customer", id: id} ->
        Map.put(input, :customer_id, id)
      _ ->
        input
    end

    with {:ok, order} <- Ordering.create_order(input) do
      ##################################
      # !!! Could be placed here, but better approach is using Absinthe macro `trigger` in
      # schema. It is not so much distributed and better for keeping track.
      ##################################
      #Absinthe.Subscription.publish(PlateSlateWeb.Endpoint, order, new_order: "*")
      #Absinthe.Subscription.publish(PlateSlateWeb.Endpoint, order, update_order: order.id)
      {:ok, %{order: order}}
    end
  end

  def ready_order(_, %{id: id}, _) do
    change_order_state(id, "ready")
  end

  def complete_order(_, %{id: id}, _) do
    change_order_state(id, "complete")
  end

  defp change_order_state(id, state) do
    order = Ordering.get_order!(id)

    with {:ok, order} <- Ordering.update_order(order, %{state: state}) do
      {:ok, %{order: order}}
    end
  end

end
