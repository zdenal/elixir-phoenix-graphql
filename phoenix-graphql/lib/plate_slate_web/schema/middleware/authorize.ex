defmodule PlateSlateWeb.Schema.Middleware.Authorize do
  @behaviour Absinthe.Middleware

  # The `role` argument is argument passed from `schema.ex`
  # wheen we using middleware there.
  def call(resolution, role) do
    with %{current_user: current_user} <- resolution.context,
    true <- correct_role?(current_user, role) do
      resolution
    else
      _ ->
        resolution
        |> Absinthe.Resolution.put_result({:error, "unauthorized"})
    end
  end

  defp correct_role?(%{}, :any), do: true
  defp correct_role?(%{role: role}, role), do: true
  defp correct_role?(_, _), do: false
end
