ExUnit.start()

{:ok, _pid} = Journal.Repo.start_link()
Ecto.Adapters.SQL.Sandbox.mode(Journal.Repo, :auto)
