defmodule Elixir.Our.Repo.Migrations.SshKey do
  use Ecto.Migration

  def change do
    create table (:ssh_key) do
      add :owner_id, references(:account), null: false
      add :name, :string
      add :type, :string
      add :fingerprint, :string, null: false, size: 32
      add :content, :binary, null: false

      timestamps type: :utc_datetime
    end

    create unique_index(:ssh_key, :fingerprint)
  end
end
