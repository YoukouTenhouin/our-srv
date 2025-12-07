defmodule Our.Repo.Migrations.User do
  use Ecto.Migration

  def change do
    create table(:account) do
      add :name, :string, null: false
      add :email, :string, null: false
      add :password, :string, null: false
      add :profile, :map

      timestamps type: :utc_datetime
    end

    create unique_index(:account, :name)
  end
end
