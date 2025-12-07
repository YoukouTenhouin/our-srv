defmodule Our.Repo.Migrations.Package do
  use Ecto.Migration

  def change do
    create table(:package) do
      add :name, :string, null: false
      add :version, :string
      add :description, :string
      add :maintainer_id, references(:account, on_delete: :nilify_all)

      timestamps type: :utc_datetime
    end

    create unique_index(:package, :name)
  end
end
