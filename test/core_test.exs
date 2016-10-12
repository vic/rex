defmodule Rex.CoreTest.Hello do
  def hello(who), do: "Hello #{who}."
  def world, do: "World"
end

defmodule Rex.CoreTest do
  use ExUnit.Case
  doctest Rex.Macro

  import Rex.Core
  import Rex.Macro, only: [to_rex: 1]
  import __MODULE__.Hello
  alias  __MODULE__.Hello

  def done, do: "done"
  def halt({data, _program, env}) do
    {[done | data], [], env}
  end

  test "pushes a number literal from program stack into data stack" do
    assert {[1], [], nil} == run_top({[], to_rex(1), nil})
  end

  test "pushes a binary literal from program stack into data stack" do
    assert {["hello"], [], nil} == run_top({[], to_rex("hello"), nil})
  end

  test "can invoke a word from context" do
    assert {[done], [], nil} == run_top({[], to_rex(halt), nil})
  end

  test "can call a non-stack function" do
    assert {[done], [], nil} == run_top({[], to_rex(^done), nil})
  end

  test "can call a non-stack function of zero arg" do
    assert {[done], [], nil} == run_top({[], to_rex(done/0), nil})
  end

  test "can call a remote function of zero arg" do
    assert {["World"], [], nil} == run_top({[], to_rex(Hello.world/0), nil})
  end

  test "can call a non-stack function of one arg" do
    assert {["Hello world."], [], nil} == run_top({["world"], to_rex(hello/1), nil})
  end

  test "a call to a remote non-stack function of two arguments" do
    assert {[3], [], nil} == run_top({[1, 2], to_rex(Kernel.+/2), nil})
  end

  test "pushes a function reference to the data stack" do
    assert {[&Kernel.+/2], [], nil} == run_top({[], to_rex(&Kernel.+/2), nil})
  end

end
