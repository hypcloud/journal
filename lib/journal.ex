defmodule Journal do
  @moduledoc """
  Journal tracks changes (i.e. Insert, Updates, Deletes) on Ecto Schemas.
  This can be useful for a variety of cases, such as for keeping an activity log
  or for auditing changes to tables over time.

  _***Note:*** this library is still very early-stage, use at your own risk._

  _***Note:*** this library has only been tested with Postgres._

  ## Setup
  Make sure to have both `ecto` and `ecto_sql` in your dependencies,
  then add `{journal: "0.1.0"}`

  First, you need to run an initialization script that will create a migration
  for a new table and a stored procedure with the following mix task:

  ```sh
  $ mix journal.init
  ```

  Now you're ready to add write-tracking to your existing Ecto.Schemas one-by-one
  by running this mix task:

  ```sh
  $ mix journal.gen schema_name
  ```

  Finally, commit your changes by running the migrations:

  ```sh
  $ mix ecto.migrate
  ```

  Once you've successfully migrated, drop the `use Journal` macro into your model
  to get access to journal of this model:
  ```elixir
  defmodule Todos.Todo do
    use Journal

    schema "todos" do
      field :title, :string
      field :status, :string
    end
  end
  ```

  ## Usage

  To get a todos history, you can now call `Todos.Todo.history_of(id)` to get the query needed
  to list the changes. You can still append to this query, e.g. for filtering or sorting purposes.

  ## More
  This feature leverages a postgres trigger as described here:
  https://www.cybertec-postgresql.com/en/tracking-changes-in-postgresql/
  """

  @callback history_of(id) :: Ecto.Query.t()
  @type id :: String.t() | Integer.t()

  defmacro __using__(_) do
    quote do
      @behaviour Journal
      resource = __MODULE__

      defmodule History do
        use Ecto.Schema
        import Ecto.Query
        @parent_module __MODULE__ |> Module.split() |> Enum.drop(-1) |> Module.concat()

        schema "journal_journal" do
          field(:table_name, :string)
          field(:operation, :string)
          embeds_one(:new_val, resource)
          embeds_one(:old_val, resource)
          field(:inserted_at, :utc_datetime_usec)
        end

        def history_of(id) do
          __MODULE__ |> get_history() |> of(id)
        end

        defp get_history(query) do
          table_name = @parent_module.__schema__(:source)
          from(q in query, where: q.table_name == ^table_name, order_by: [desc: :inserted_at])
        end

        defp of(query, id) do
          from(q in query,
            where: fragment("(old_val->'id' = ?)", ^id) or fragment("(new_val->'id' = ?)", ^id)
          )
        end
      end

      @impl true
      def history_of(id) do
        History.history_of(id)
      end
    end
  end
end
