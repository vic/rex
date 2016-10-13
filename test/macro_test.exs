defmodule Rex.MacroTest do
  use ExUnit.Case

  doctest Rex.Macro

  describe "Rex.Macro.to_rex/1" do

    defp remove_meta(q), do: Macro.prewalk(q, &Macro.update_meta(&1, fn _ -> [] end))
    defmacrop qrex(expr), do: Rex.Macro.to_rex_ast(expr) |> remove_meta |> Macro.escape
    defmacrop qex(expr), do: expr |> remove_meta |> Macro.escape

    test "a literal is returned as a program that pushes that literal" do
      assert [1] = qrex(1)
    end

    test "a single name is converted to itself" do
      assert [{:foo, _, nil}] = qrex(foo)
    end

    test "a sequence of names is flattened" do
      assert [{:foo, _, nil}, {:bar, _, nil}, {:baz, _, nil}] = qrex(foo bar baz)
    end

    test "an operator application is converted into postfix notation" do
      assert [1, 2, {:+, _, nil}] = qrex(1 + 2)
    end

    test "the ~> operator indicates postfix program order" do
      assert [{:foo, _, nil}, {:bar, _, nil}, {:baz, _, nil}] = qrex(foo ~> bar ~> baz)
    end

    test "the <~ operator indicates prefix program order" do
      assert [{:baz, _, nil}, {:bar, _, nil}, {:foo, _, nil}] = qrex(foo <~ bar <~ baz)
    end

    test "var reference is indicated by ^" do
      assert [{:^, _, [{:foo, _, nil}]}] = qrex(^foo)
    end

    test "local function references are not affected" do
      assert qex([&foo/1]) == qrex(&foo/1)
    end

    test "remote function references are not affected" do
      assert qex([&Moo.foo/1]) == qrex(&Moo.foo/1)
    end

    test "local function application is not affected" do
      assert qex([foo/1]) == qrex(foo/1)
    end

    test "remote function application is not affected" do
      assert qex([Foo.foo/1]) == qrex(Foo.foo/1)
    end

    test "many var references in same line are flattened" do
      assert [{:^, _, [{:foo, _, nil}]},
              {:^, _, [{:bar, _, nil}]},
              {:^, _, [{:baz, _, nil}]}
             ] = qrex(^foo ^bar ^baz)
    end

    test "a code block can be given and is converted to postfix notation" do
      assert [{:foo, _, nil}, {:bar, _, nil}, {:baz, _, nil}] = (
        qrex do
          foo
          bar baz
        end)
    end

    test "quote is not modified" do
      assert [{:foo, _, nil}, {:quote, _, [{:+, _, [2, 1]}]}] = qrex(foo quote 2 + 1)
    end

  end
end
