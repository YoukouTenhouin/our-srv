defmodule OurWeb.PackageJSON do
  alias Our.Schemas.Package

  defp data(%Package{} = pkg) do
    ret = %{
      name: pkg.name,
      version: pkg.version,
      description: pkg.description,
    }
    if Ecto.assoc_loaded?(pkg.maintainer) do
      ret |> Map.put(:maintainer, pkg.maintainer.name)
    else
      ret
    end
  end

  def show(%{package: pkg}) do
    %{data: data(pkg)}
  end

  def index(%{packages: pkgs}) do
    %{data: for(p <- pkgs, do: data(p))}
  end
end
