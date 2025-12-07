defmodule OurWeb.UserController do
  use Phoenix.Controller, formats: [json: "JSON"]

  action_fallback OurWeb.FallbackController

  alias Our.Repo
  alias Our.Schemas.User

  alias OurWeb.Auth

  import Ecto.Query

  defp get_user(name) do
    name = name |> String.trim() |> String.downcase()
    query = from u in User,
		 where: fragment("LOWER(?)", u.name) == ^name
    case Repo.one query do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  def show(conn, %{"name" => name} = _params) do
    with {:ok, user} <- get_user(name) do
      render(conn, :show, user: user)
    end
  end

  def create(conn, params) do
    with password when not is_nil(password) <- Map.get(params, "password"),
	 password <- Auth.hash_password(password),
	 params <- Map.put(params, "password", password),
	 changeset <- %User{} |> User.changeset(params),
	 {:ok, user} <- Repo.insert changeset do
      render(conn, :show, user: user)
    else
      _ ->
	{:error, :unprocessable_entity, "missing password"}
    end
  end
end
