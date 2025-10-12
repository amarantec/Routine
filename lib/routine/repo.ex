defmodule Routine.Repo do
  use Ecto.Repo,
    otp_app: :routine,
    adapter: Ecto.Adapters.Postgres
end
