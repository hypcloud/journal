defmodule Mix.Tasks.Journal.Init do
  use Mix.Task
  import Mix.Generator

  @moduledoc """
  Generate a migration to add the journal table, indexes and stored procedure to your schema.

  ## Usage
  ```sh
    $ mix journal.init
  ```
  """

  def run(args) do
    change = EEx.eval_string(migration_template([]))

    ["create_journal#{args}", "--change=#{change}"]
    |> Mix.Tasks.Ecto.Gen.Migration.run()
  end

  embed_template(:migration, """
      create table(:journal_journal) do
        add(:table_name, :text)
        add(:operation, :text)
        add(:new_val, :map)
        add(:old_val, :map)
        add(:inserted_at, :utc_datetime_usec, default: fragment(\"clock_timestamp()\"))
      end

      create index(:journal_journal, :inserted_at)
      create index(:journal_journal, :table_name)
      create index(:journal_journal, :operation)

      execute(
        \"
      CREATE FUNCTION change_trigger ()
          RETURNS TRIGGER
          AS $$
      BEGIN
          IF TG_OP = 'INSERT' THEN
              INSERT INTO journal_journal (table_name, operation, new_val)
              VALUES (TG_RELNAME, TG_OP, row_to_json(NEW));
              RETURN NEW;
          ELSIF TG_OP = 'UPDATE' THEN
              INSERT INTO journal_journal (table_name, operation, new_val, old_val)
              VALUES (TG_RELNAME, TG_OP, row_to_json(NEW), row_to_json(OLD));
              RETURN NEW;
          ELSIF TG_OP = 'DELETE' THEN
              INSERT INTO journal_journal (table_name, operation, old_val)
              VALUES (TG_RELNAME, TG_OP, row_to_json(OLD));
              RETURN OLD;
          END IF;
      END;
      $$
      LANGUAGE 'plpgsql'
      SECURITY DEFINER;
      \",
        \"DROP FUNCTION IF EXISTS change_trigger ();\"
      )
  """)
end
