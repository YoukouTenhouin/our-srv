defmodule Our.Schemas.Package do
  use Ecto.Schema

  import Ecto.Changeset

  alias Our.Schemas.User

  schema "package" do
    field :name, :string
    field :version, :string
    field :description, :string

    belongs_to :maintainer, User, foreign_key: :maintainer_id

    timestamps type: :utc_datetime
  end

  def changeset(package, params) do
    package
    |> cast(params, [:name, :version, :description, :maintainer_id])
    |> validate_format(:name, ~r/^[a-zA-Z0-9.+_-]+$/)
    |> unique_constraint(:name)
  end
end
