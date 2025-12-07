defmodule Our.Schemas.SSHKey do
  use Ecto.Schema

  import Ecto.Changeset

  alias Our.Schemas.User

  schema "ssh_key" do
    field :name, :string
    field :type, Ecto.Enum, values: [:rsa, :ecdsa, :ed25519]
    field :fingerprint, :string
    field :content, :binary

    belongs_to :owner, User, foreign_key: :owner_id

    timestamps type: :utc_datetime
  end

  defp put_fingerprint(key) do
    case get_change(key, :content) do
      nil -> key
      data ->
	fp =
	  Blake2.hash2b(data, 16, "")
	  |> Base.encode16(case: :lower)
	put_change(key, :fingerprint, fp)
    end
  end

  def changeset(key, params) do
    key
    |> cast(params, [:name, :type, :content, :owner_id])
    |> validate_length(:content, count: :bytes, max: 2048)
    |> validate_length(:name, max: 64)
    |> put_fingerprint()
    |> unique_constraint(:fingerprint)
  end
end
