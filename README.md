# Journal

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

For example:

```elixir
{:ok, todo} = Journal.Repo.insert(%Journal.Todo{title: "Foo", status: "open"})
Journal.Todo.history_of(todo.id) |> Journal.Repo.all()

[
  %Journal.Todo.History{
    __meta__: #Ecto.Schema.Metadata<:loaded, "journal_journal">,
    id: 1,
    inserted_at: ~U[2019-12-03 17:21:04.639808Z],
    new_val: %Journal.Todo{
      __meta__: #Ecto.Schema.Metadata<:loaded, "todos">,
      id: 1,
      status: "open",
      title: "Foo"
    },
    old_val: nil,
    operation: "INSERT",
    table_name: "todos"
  }
]

Journal.Repo.update(cast(todo, %{title: "Bar"}, [:title]))
Journal.Todo.history_of(todo.id) |> Journal.Repo.all()

[
  %Journal.Todo.History{
    __meta__: #Ecto.Schema.Metadata<:loaded, "journal_journal">,
    id: 2,
    inserted_at: ~U[2019-12-03 17:21:04.643228Z],
    new_val: %Journal.Todo{
      __meta__: #Ecto.Schema.Metadata<:loaded, "todos">,
      id: 1,
      status: "open",
      title: "Bar"
    },
    old_val: %Journal.Todo{
      __meta__: #Ecto.Schema.Metadata<:loaded, "todos">,
      id: 1,
      status: "open",
      title: "Foo"
    },
    operation: "UPDATE",
    table_name: "todos"
  },
  %Journal.Todo.History{
    __meta__: #Ecto.Schema.Metadata<:loaded, "journal_journal">,
    id: 1,
    inserted_at: ~U[2019-12-03 17:21:04.639808Z],
    new_val: %Journal.Todo{
      __meta__: #Ecto.Schema.Metadata<:loaded, "todos">,
      id: 1,
      status: "open",
      title: "Foo"
    },
    old_val: nil,
    operation: "INSERT",
    table_name: "todos"
  }
]
```

## More

This feature leverages a postgres trigger as described here:
https://www.cybertec-postgresql.com/en/tracking-changes-in-postgresql/
