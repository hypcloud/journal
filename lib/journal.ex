defmodule Journal do
  @moduledoc """
  This mdule provides the functionality for tracking changes of resources.
  To use it with an existing Ecto.Schema you need to add a migration for the trigger with

  ```bash
  $ mix journal.gen model_name
  ```

  and import the Macro in the model:

  ```elixir

  defmodule Todos.Todo do
    use Journal

    schema "todos" do
      # omitted...
    end
  end
  ```

  To get a todos history, you can now call `Todos.Todo.history_of(id)` to get the query needed
  to list the changes. You can still append to this query, e.g. for filtering or sorting purposes.

  Note: this feature leverages a postgres trigger as described here:
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
