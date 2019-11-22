defmodule Journal.Todo do
  use Ecto.Schema

  use Journal

  schema "todos" do
    field(:title, :string)
    field(:status, :string)
  end
end
