defmodule PhoenixLive.Repo.Migrations.CreateCountersAndProbe do
  use Ecto.Migration

  def change do
    create table(:counters, primary_key: false) do
      add :name, :string, primary_key: true
      add :value, :bigint, null: false, default: 0
    end

    execute "INSERT INTO counters (name, value) VALUES ('clicks', 0)", ""

    create table(:zoo_probe) do
      add :token, :string, null: false
      add :inserted_at, :utc_datetime, null: false, default: fragment("now()")
    end
  end
end
