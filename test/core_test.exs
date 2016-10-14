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
  def halt({data, _program}) do
    {[done | data], []}
  end

  test "pushes a number literal from program stack into data stack" do
    assert {[1], []} == run_top({[], to_rex(1)})
  end

  test "pushes a binary literal from program stack into data stack" do
    assert {["hello"], []} == run_top({[], to_rex("hello")})
  end

  test "can invoke a word from context" do
    assert {[done], []} == run_top({[], to_rex(halt)})
  end

  test "can call a non-stack function" do
    assert {[done], []} == run_top({[], to_rex(^done)})
  end

  test "can call a non-stack function of zero arg" do
    assert {[done], []} == run_top({[], to_rex(done/0)})
  end

  test "can call a remote function of zero arg" do
    assert {["World"], []} == run_top({[], to_rex(Hello.world/0)})
  end

  test "can call a non-stack function of one arg" do
    assert {["Hello world."], []} == run_top({["world"], to_rex(hello/1)})
  end

  test "a call to a remote non-stack function of two arguments" do
    assert {[3], []} == run_top({[1, 2], to_rex(Kernel.+/2)})
  end

  test "pushes a function reference to the data stack" do
    assert {[&Kernel.+/2], []} == run_top({[], to_rex(&Kernel.+/2)})
  end

end
