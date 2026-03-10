defmodule Sparkdeck.Repo do
  use Ecto.Repo,
    otp_app: :sparkdeck,
    adapter: Ecto.Adapters.Postgres
end
