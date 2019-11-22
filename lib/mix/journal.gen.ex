defmodule Mix.Tasks.Journal.Gen do
  use Mix.Task
  import Mix.Generator

  @moduledoc """
  Generate a migration to add tracking capabilities to an Ecto Schema

  ## Usage
  ```sh
    $ mix journal.gen [SCHEMA_NAME]
  ```
  """

  def run([table_name]) do
    change = EEx.eval_string(migration_template(table_name: table_name))

    ["create_history_for_#{table_name}", "--change=#{change}"]
    |> Mix.Tasks.Ecto.Gen.Migration.run()
  end

  embed_template(:migration, """
      execute(
        \"
        CREATE TRIGGER t
        AFTER INSERT
        OR UPDATE
        OR DELETE ON <%= @table_name %>
        FOR EACH ROW
        EXECUTE PROCEDURE change_trigger ();
        \",
        \"DROP TRIGGER IF EXISTS t ON <%= @table_name %>;\"
      )
  """)
end
