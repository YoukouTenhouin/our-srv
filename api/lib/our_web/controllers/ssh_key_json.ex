defmodule OurWeb.SSHKeyJSON do
  alias Our.Schemas.SSHKey

  defp data(%SSHKey{} = key) do
    ret = %{
      id: key.id,
      name: key.name,
      type: key.type,
      fingerprint: key.fingerprint,
      content: Base.encode64(key.content)
    }
    if Ecto.assoc_loaded?(key.owner) do
      ret |> Map.put(:owner, key.owner.name)
    else
      ret
    end
  end

  def show(%{key: key}) do
    %{data: data(key)}
  end

  def index(%{keys: keys}) do
    %{data: for(k <- keys, do: data(k))}
  end

  def delete(_) do
    %{success: true}
  end
end
