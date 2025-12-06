defmodule OurWeb.SSHKeyController do
  use Phoenix.Controller, formats: [json: "JSON"]

  action_fallback OurWeb.FallbackController

  alias Our.Repo
  alias Our.Schemas.User
  alias Our.Schemas.SSHKey

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

  def index(conn, %{"user" => username} = _params) do
    with {:ok, user} <- get_user(username) do
      user = Repo.preload(user, :keys)
      render(conn, :index, keys: user.keys)
    end
  end

  def do_create_key(params, user) do
    with key when not is_nil(key) <- Map.get(params, "content"),
	 {:ok, key} <- Base.decode64(key) do
      params = params
      |> Map.put("owner_id", user.id)
      |> Map.put("content", key)

      %SSHKey{}
      |> SSHKey.changeset(params)
      |> Repo.insert
    else
      nil -> {:error, :not_found}
      :error -> {:error, :unprocessable_entity, "invalid base64"}
    end
  end

  def create(conn, params) do
    with {:ok, token} <- Auth.get_token_from_conn(conn),
	 {:ok, user} <- Auth.user_from_access_token(token),
	 {:ok, key} <- do_create_key(params, user) do
      render(conn, :show, key: key)
    end
  end

  def delete(conn, %{"id" => id} = _params) do
    with {:ok, token} <- Auth.get_token_from_conn(conn),
	 {:ok, user} <- Auth.user_from_access_token(token) do
      query = from k in SSHKey,
		   where: k.id == ^String.to_integer(id),
		   where: k.owner_id == ^user.id
      with {count, _} <- Repo.delete_all query do
	if count > 0 do
	  render(conn, :delete)
	else
	  {:error, :not_found}
	end
      end
    end
  end

  def show(conn, %{"fingerprint" => fp} = _params) do
    fp = fp |> String.downcase()
    with key when not is_nil(key) <-
	   Repo.get_by SSHKey, fingerprint: fp do
      key = Repo.preload(key, :owner)
      render(conn, :show, key: key)
    else
      nil -> {:error, :not_found}
    end
  end
end
