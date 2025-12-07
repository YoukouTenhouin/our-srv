defmodule OurWeb.PackageController do
  use Phoenix.Controller, formats: [json: "JSON"]

  action_fallback OurWeb.FallbackController

  alias Our.Repo
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

  defp do_create_pkg(params, maintainer) do
    params = Map.put(params, "maintainer_id", maintainer.id)
    %Package{}
    |> Package.changeset(params)
    |> Repo.insert
  end

  def create(conn, params) do
    with {:ok, token} <- Auth.get_token_from_conn(conn),
	 {:ok, user} <- Auth.user_from_access_token(token),
	 {:ok, package} <- do_create_pkg(params, user) do
      render(conn, :show, package: package)
    end
  end
end
