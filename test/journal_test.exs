defmodule JournalTest do
  use ExUnit.Case, async: false
  import Ecto.Changeset
  doctest Journal

  setup do
    clean_migration_folder()

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Journal.Repo, sandbox: false)
  end

  test "mix.journal.init" do
    [init_path] = Mix.Tasks.Journal.Init.run([])
    assert File.exists?(init_path)

    # Wait for 1 second to make sure the Init migration gets created before Gen
    Process.sleep(1000)

    [gen_path] = Mix.Tasks.Journal.Gen.run(["todos"])

    assert File.exists?(gen_path)
    assert gen_path =~ "create_history_for_todos"
    assert :ok == Mix.Tasks.Ecto.Migrate.run([])

    {:ok, todo} = Journal.Repo.insert(%Journal.Todo{title: "Foo", status: "open"})
    {:ok, _} = Journal.Repo.update(cast(todo, %{title: "Bar"}, [:title]))
    {:ok, _} = Journal.Repo.delete(todo)

    [del, upd, ins] = Journal.Todo.history_of(todo.id) |> Journal.Repo.all()

    assert ins.operation == "INSERT"
    assert ins.old_val == nil
    assert ins.new_val.title == "Foo"

    assert upd.operation == "UPDATE"
    assert upd.old_val.title == "Foo"
    assert upd.new_val.title == "Bar"

    assert del.operation == "DELETE"
    assert del.old_val.title == "Bar"
    assert del.new_val == nil

    on_exit("clean migrations", &clean_migration_folder/0)
  end

  defp clean_migration_folder do
    Path.wildcard("priv/repo/migrations/*") |> Enum.each(fn path -> File.rm(path) end)
  end
end
