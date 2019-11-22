import Config

config :journal, ecto_repos: [Journal.Repo]

config :journal, Journal.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "journal_test",
  hostname: "localhost",
  poolsize: 10,
  pool: Ecto.Adapters.SQL.Sandbox
