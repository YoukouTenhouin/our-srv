defmodule Our.Schemas.User do
  use Ecto.Schema

  import Ecto.Changeset

  alias Our.Schemas.Package
  alias Our.Schemas.SSHKey

  schema "account" do
    field :name, :string
    field :email, :string
    field :password, :string, redact: true
    field :profile, :map

    has_many :packages, Package, foreign_key: :maintainer_id
    has_many :keys, SSHKey, foreign_key: :owner_id

    timestamps type: :utc_datetime
  end

  def changeset(user, params) do
    user
    |> cast(params, [:name, :email, :password, :profile])
    |> unique_constraint(:name)
  end
end
