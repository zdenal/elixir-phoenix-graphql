# This Plug is pipelined in `api` pipeline in router.ex
defmodule PlateSlateWeb.Context do
  @behaviour Plug
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)
    IO.inspect [context: context]
    # put into the context (it is 3rd params in resolver or in middlewares
    # we can reach it via `resolution.context`) our informationts
    Absinthe.Plug.put_options(conn, context: context)
  end

  defp build_context(conn) do
    IO.inspect get_req_header(conn, "authorization")

    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
    {:ok, data} <- PlateSlateWeb.Authentication.verify(token),
    %{} = user <- get_user(data) do
      %{current_user: user}
    else
      _ -> %{}
    end
  end

  defp get_user(%{id: id, role: role}) do
    PlateSlate.Accounts.lookup(role, id)
  end
end
