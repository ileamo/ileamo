defmodule Ileamo.Repo do
  use Ecto.Repo,
    otp_app: :ileamo,
    adapter: Ecto.Adapters.Postgres
end
