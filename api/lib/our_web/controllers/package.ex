defmodule OurWeb.PackageController do
  use Phoenix.Controller, formats: [json: "JSON"]

  action_fallback OurWeb.FallbackController

  alias Our.Repo
  alias Our.Schemas.User
  alias Our.Schemas.Package

  alias OurWeb.Auth

  def index(conn, _params) do
    pkgs = Repo.all Package
    render(conn, :index, packages: pkgs)
  end

  defp get_pkg(name) do
    name = name |> String.trim()
    case Repo.get_by Package, name: name do
      nil -> {:error, :not_found}
      pkg -> {:ok, pkg |> Repo.preload(:maintainer)}
    end
  end

  def show(conn, %{"name" => name} = _params) do
    with {:ok, pkg} <- get_pkg(name) do
      render(conn, :show, package: pkg)
    end
  end

  defp do_create_pkg(params) do
    %Package{}
    |> Package.create(params)
    |> Repo.insert
  end

  defp do_update_pkg(pkg, params) do
    pkg
    |> Package.update(params)
    |> Repo.update
  end

  defp put_maintainer_id(params) do
    case Map.get(params, "maintainer") do
      nil -> {:ok, params}
      username ->
	username = username |> String.trim() |> String.downcase()
	case Repo.get_by User, name: username do
	  nil -> {:error, :not_found}
	  user -> {:ok, params |> Map.put("maintainer_id", user.id)}
	end
    end
  end

  def create(conn, params) do
    # TODO auth
    with {:ok, params} <- put_maintainer_id(params),
	 {:ok, package} <- do_create_pkg(params) do
      render(conn, :show, package: package)
    end
  end

  def update(conn, %{"name" => name} = params) do
    # TODO auth
    with {:ok, params} <- put_maintainer_id(params),
	 {:ok, original} <- get_pkg(name),
	 {:ok, updated} <- do_update_pkg(original, params) do
      render(conn, :show, package: updated)
    end
  end

  def delete(conn, %{"name" => name}) do
    with {:ok, token} = Auth.get_token_from_conn(conn),
	 {:ok, user} = Auth.user_from_access_token(token),
	 {:ok, package} = get_pkg(name) do
      if package.maintainer.id == user.id do
	with {:ok, _} <- Repo.delete package do
	  render(conn, :delete)
	end
      else
	{:error, :forbidden}
      end
    end
  end
end
