defmodule Our.Schemas.Package do
  use Ecto.Schema

  import Ecto.Changeset

  alias Our.Schemas.User

  schema "package" do
    field :name, :string
    field :version, :string
    field :release, :string
    field :license, :string
    field :description, :string
    field :requires, {:array, :string}

    belongs_to :maintainer, User, foreign_key: :maintainer_id

    timestamps type: :utc_datetime
  end

  @fields_update [
     :version,
     :release,
     :license,
     :description,
     :requires,
     :maintainer_id
   ]

  @fields_create [:name | @fields_update]

  def create(package, params) do
    package
    |> cast(params, @fields_create)
    |> validate_format(:name, ~r/^[a-zA-Z0-9.+_-]+$/)
    |> unique_constraint(:name)
  end

  def update(package, params) do
    package
    |> cast(params, @fields_update)
  end
end
