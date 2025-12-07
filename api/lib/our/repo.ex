defmodule Our.Repo do
  use Ecto.Repo,
    otp_app: :our,
    adapter: Ecto.Adapters.Postgres
end
