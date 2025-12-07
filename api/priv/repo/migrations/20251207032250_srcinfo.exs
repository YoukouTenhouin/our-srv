defmodule Our.Repo.Migrations.Srcinfo do
  use Ecto.Migration

  def change do
    alter table(:package) do
      add :release, :string
      add :license, :string
      add :requires, {:array, :string}, default: []
    end
  end
end
