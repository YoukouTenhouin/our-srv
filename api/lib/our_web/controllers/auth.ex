defmodule OurWeb.AuthController do
  use Phoenix.Controller, formats: [json: "JSON"]

  action_fallback OurWeb.FallbackController

  alias Our.Repo
  alias Our.Schemas.User
  alias OurWeb.Auth

  import Ecto.Query

  defp get_user(name) do
    name = name |> String.trim()
    query = from u in User,
		 where: fragment("LOWER(?)", u.name) == ^name
    case Repo.one query do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  defp do_login(username, password) do
    with {:ok, user} <- get_user(username) do
      if Auth.verify_password(user, password) do
	Auth.generate_user_tokens(user)
      else
	{:error, :unauthorized}
      end
    end
  end

  def login(conn, %{"username" => username, "password" => password}) do
    with {:ok, auth_token, refresh_token} <- do_login(username, password) do
      render(conn, :token, auth_token: auth_token, refresh_token: refresh_token)
    end
  end

  def refresh(conn, _params) do
    with {:ok, token} <- Auth.get_token_from_conn(conn),
	 {:ok, user} <- Auth.user_from_refresh_token(token),
	 {:ok, auth_token, refresh_token} <- Auth.generate_user_tokens(user) do
      render(conn, :token, auth_token: auth_token, refresh_token: refresh_token)
    end
  end

  def info(conn, _params) do
    with {:ok, token} <- Auth.get_token_from_conn(conn),
	 {:ok, user} <- Auth.user_from_access_token(token) do
      conn
      |> put_view(json: OurWeb.UserJSON)
      |> render(:show, user: user)
    else
      _ ->
	{:error, :unauthorized}
    end
  end
end
