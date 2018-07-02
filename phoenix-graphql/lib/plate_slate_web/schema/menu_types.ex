defmodule PlateSlateWeb.Schema.MenuTypes do
  use Absinthe.Schema.Notation

  alias PlateSlateWeb.{Resolvers}
  alias PlateSlateWeb.Schema.Middleware
  alias PlateSlate.Menu
  import Absinthe.Resolution.Helpers

  # Example of union
  #union :search_result do
    #types [:menu_item, :category]
    #resolve_type fn
      #%PlateSlate.Menu.Item{}, _ -> :menu_item
      #%PlateSlate.Menu.Category{}, _ -> :category
      #_, _ -> nil
    #end
  #end

  # Example of interface. Diff with `union` is the interface
  # declare set of fields that any member must define. Don't
  # forget declare interfaces in required objects!!!
  interface :search_result do
    field :name, :string
    resolve_type fn
      %PlateSlate.Menu.Item{}, _ -> :menu_item
      %PlateSlate.Menu.Category{}, _ -> :category
      _, _ -> nil
    end
  end

  input_object :menu_item_filter do
    @desc "Matching a name"
    field :name, :string

    @desc "Matching a category name"
    field :category, :string

    @desc "Matching a tag"
    field :tag, :string

    @desc "Priced above a vale"
    field :priced_above, :decimal

    @desc "Priced below a value"
    field :priced_below, :decimal

    @desc "Added before this date"
    field :added_before, :date

    @desc "Added after this date"
    field :added_after, :date
  end

  object :menu_item do
    interfaces [:search_result]
    field :id, :id
    field :name, :string
    field :description, :string
    field :added_on, :date
    field :price, :decimal
    field :allergy_info, list_of(:allergy_info)
    #field :category, :category do
      #resolve &Resolvers.Menu.category_for_item/3
    #end
    # This `dataloader` is Absinthe helper function which has same pattern as calling fn above handy implemented.
    field :category, :category, resolve: dataloader(Menu)

    field :order_history, :order_history do
      arg :since, :date
      middleware Middleware.Authorize, "employee"
      resolve &Resolvers.Ordering.order_history/3
    end
  end

  object :order_history do
    field :orders, list_of(:order) do
      resolve &Resolvers.Ordering.orders/3
    end
    field :quantity, non_null(:integer) do
      resolve Resolvers.Ordering.stat(:quantity)
    end
    field :gross, non_null(:float) do
      resolve Resolvers.Ordering.stat(:gross)
    end
  end

  object :allergy_info do
    field :allergen, :string
    field :severity, :string
  end

  object :category do
    interfaces [:search_result]
    field :id, :id
    field :name, :string
    field :description, :string
    field :items, list_of(:menu_item) do
      arg :filter, :menu_item_filter
      arg :order, type: :sort_order, default_value: :asc
      #resolve &Resolvers.Menu.items_for_category/3
      # This `dataloader` is Absinthe helper function which has same pattern as calling fn above handy implemented.
      resolve dataloader(Menu, :items)
    end
  end

  object :menu_queries do
    @desc "The list of available items on the menu"
    field :menu_items, list_of(:menu_item) do
      arg :filter, :menu_item_filter
      arg :order, :sort_order, default_value: :asc
      resolve &Resolvers.Menu.menu_items/3
    end
  end

  input_object :menu_item_input do
    field :name, non_null(:string)
    field :description, :string
    field :price, non_null(:decimal)
    field :category_id, non_null(:id)
  end

  object :menu_item_result do
    field :menu_item, :menu_item
    field :errors, list_of(:input_error)
  end

  @desc "An error structure returned."
  object :input_error do
    field :key, non_null(:string)
    field :message, non_null(:string)
  end
end
