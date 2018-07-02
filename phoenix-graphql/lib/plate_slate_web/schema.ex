#---
# Excerpted from "Craft GraphQL APIs in Elixir with Absinthe",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material,
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose.
# Visit http://www.pragmaticprogrammer.com/titles/wwgraphql for more book information.
#---
defmodule PlateSlateWeb.Schema do
  use Absinthe.Schema

  alias PlateSlate.{Menu, Repo}
  alias PlateSlateWeb.{Resolvers}
  alias PlateSlateWeb.Schema.Middleware

  def middleware(middleware, field, object) do
    middleware
    |> apply(:errors, field, object)
    |> apply(:get_string, field, object)
    |> apply(:debug, field, object)
  end

  defp apply(middleware, :errors, _field, %{identifier: :mutation}) do
    middleware ++ [Middleware.ChangesetErrors]
  end
  defp apply([], :get_string, field, %{identifier: :allergy_info}) do
    [{Absinthe.Middleware.MapGet, to_string(field.identifier)}]
  end
  defp apply(middleware, :debug, _field, _object) do
    if System.get_env("DEBUG") do
      [{Middleware.Debug, :start}] ++ middleware
    else
      middleware
    end
  end
  defp apply(middleware, _, _, _) do
    middleware
  end

  def dataloader() do
    alias PlateSlate.Menu
    Dataloader.new
    |> Dataloader.add_source(Menu, Menu.data())
  end

  def context(ctx) do
    Map.put(ctx, :loader, dataloader())
  end

  # it needs an external way of knowing what plugins to run callbacks for caused by Dataloader
  def plugins do
    [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults]
  end

  # Example of decomposing
  import_types __MODULE__.MenuTypes
  import_types __MODULE__.OrderingTypes
  import_types __MODULE__.AccountsTypes
  # Make possible use directives as @action, @put from our serverside app (eg. /admin)
  import_types Absinthe.Phoenix.Types

  scalar :date do
    parse fn input ->
      case Date.from_iso8601(input.value) do
        {:ok, date} -> {:ok, date}
        _ -> :error
      end
    end

    serialize fn date ->
      Date.to_iso8601(date)
    end
  end

  scalar :decimal do
    parse fn
      %{value: value}, _ -> Decimal.parse(value)
      _, _ -> :error
    end

    serialize &to_string/1
  end

  enum :sort_order do
    value :asc
    value :desc
  end

  query do
    # Example of decomposing
    import_fields :menu_queries

    field :search, list_of(:search_result) do
      arg :matching, non_null(:string)
      resolve &Resolvers.Menu.search/3
    end

    field :menu_item, :menu_item do
      arg :id, non_null(:id)
      resolve &Resolvers.Menu.get_item/3
    end

  # Example of keeping it in schema.
  # Could be also in separated file as menu_items are.
    @desc "The list of categories"
    field :categories, list_of(:category) do
      arg :filter, :category_filter # Custom type defined below by `input_object`
      arg :order, :sort_order, default_value: :asc
      resolve &Resolvers.Menu.categories/3
    end

    # this make possilbe to do this `me` requests which indicating that
    # result in this context are affected by current_user context. Like
    # we can see `menuItems` query is not affected by current_user (always same result)
    # so it is not in `me` query context.
    # {
    # me {
      # name
      # ... on Customer {
         #orders { id}
      # }
      # }
    # menuItems { name }
    #}
    field :me, :user do
      middleware Middleware.Authorize, :any
      resolve &Resolvers.Accounts.me/3
    end
  end

  mutation do
    field :create_menu_item, :menu_item_result do
      arg :input, non_null(:menu_item_input)
      middleware Middleware.Authorize, "employee"
      resolve &Resolvers.Menu.create_item/3
    end

    field :update_menu_item, :menu_item_result do
      arg :id, non_null(:id)
      arg :input, non_null(:menu_item_input)
      middleware Middleware.Authorize, "employee"
      resolve &Resolvers.Menu.update_item/3
    end

    field :place_order, :order_result do
      arg :input, non_null(:place_order_input)
      middleware Middleware.Authorize, :any
      resolve &Resolvers.Ordering.place_order/3
    end

    field :ready_order, :order_result do
      arg :id, non_null(:id)
      middleware Middleware.Authorize, "employee"
      resolve &Resolvers.Ordering.ready_order/3
    end

    field :complete_order, :order_result do
      arg :id, non_null(:id)
      middleware Middleware.Authorize, "employee"
      resolve &Resolvers.Ordering.complete_order/3
    end

    field :login, :session do
      arg :email, non_null(:string)
      arg :password, non_null(:string)
      arg :role, non_null(:role)
      resolve &Resolvers.Accounts.login/3
      # Phoenix channel connection is stateful.
      # If a GraphQL document makes a change to the context,
      # this will affect other subsequent documents that are executed by that client.
      # This middleware is for subscription effective authentication purposes.
      middleware fn res, _ ->
        with %{value: %{user: user}} <- res do
          %{res | context: Map.put(res.context, :current_user, user)}
        end
      end
    end
  end

  subscription do
    field :new_order, :order do
      config fn _args, %{context: context} ->
        case context[:current_user] do
          # Only Employees can see feeds from topic "*"
          %{role: "employee"} -> {:ok, topic: "*"}
          # Customers can see feeds only with topic of their `id`
          %{role: "customer", id: id} -> {:ok, topic: id}
          _ -> {:error, "unauthorized"}
        end
      end

      trigger [:place_order], topic: fn
        %{order: order} -> ["*", order.customer_id]
        _ -> []
      end

      resolve fn %{order: order}, _, _ ->
        {:ok, order}
      end

      # This resolver is not needed. It is here only
      # for logging purposes
      #resolve fn root, _, _ ->
        #IO.inspect(root)
        #{:ok, root}
      #end
    end

    field :update_order, :order do
      arg :id, non_null(:id)

      config fn args, _info -> {:ok, topic: args.id} end

      trigger [:ready_order, :complete_order], topic: fn
        %{order: order} -> [order.id]
        _ -> []
      end

      resolve fn %{order: order}, _, _ ->
        {:ok, order}
      end
    end
  end

  # Example of keeping it in schema.
  # Could be also in separated file as menu_items are.
  input_object :category_filter do
    @desc "Matching a name"
    field :name, :string
  end
end
