defmodule PlateSlateWeb.Schema.AccountsTypes do
  use Absinthe.Schema.Notation


  enum :role do
    value :employee
    value :customer
  end

  object :session do
    field :token, :string
    field :user, :user
  end

  interface :user do
    field :email, :string
    field :name, :string
    # this make possilbe to do this request:
    # {
    # me {
      # name
      # __typename
      # ... on Customer {
         #orders { id}
      # }
      # ... on Employee {
         #email
      # }
      # }
    #}
    resolve_type fn
      %{role: "employee"}, _ -> :employee
      %{role: "customer"}, _ -> :customer
    end
  end

  object :employee do
    interface :user
    field :email, :string
    field :name, :string
  end

  object :customer do
    # Other fields
    interface :user
    field :email, :string
    field :name, :string
    field :orders, list_of(:order) do
      resolve fn customer, _, _ ->
        import Ecto.Query

        orders =
          PlateSlate.Ordering.Order
          |> where(customer_id: ^customer.id)
          |> PlateSlate.Repo.all

        {:ok, orders}
      end
    end
  end
end
