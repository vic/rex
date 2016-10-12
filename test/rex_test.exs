quote do
defmodule Rex.Examples do
  use Rex

  drex double(a)     (a * 2)
  drex double_swap   double swap double
  drex mult          Kernel.*/2
  drex triple        3 ~> mult
  drex puts          IO.puts/1 ~> drop

  drex sum           0 ~> (&Kernel.+/2) ~> List.foldr/3
  drex sumr          List.foldr/3 <~ (&Kernel.+/2) <~ 0

  drex sum3(c, b, a) (a + b + c)

  def answer, do: 42
  def square(x), do: x * x

  drex tatata do
    triple show
    swap double
  end

  def a(stack) do
    stack
  end

  drex caca(a, _, c) do
    ^c
    ^a
    ^c ^a
  end

end

defmodule Rex.ExamplesTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  use Rex

  doctest Rex
  doctest Rex.ReadmeExamples

  import Rex.Examples

  test "swap changes topmost two elements on data stack" do
    assert [2, 1, 3] == swap([1, 2, 3])
  end

  test "double duplicates topmost value" do
    assert [6, 1] == double([3, 1])
  end

  test "can call swap with rex" do
    assert [2, 1, 3] == [1, 2, 3] |> rex(swap)
  end

  test "can call a sequence of functions" do
    assert [6, 2, 5] == [1, 3, 5] |> rex(double ~> swap ~> double)
  end

  test "can place arguments as part of program" do
    assert [6, 2, 5] == [] |> rex(5 ~> 3 ~> 1 ~> double ~> swap ~> double)
  end

  test "can use drex to define a name for a program" do
    assert [6, 2, 5] == [] |> rex(5 ~> 3 ~> 1 ~> double_swap)
  end

  test "can call to native function reference" do
    assert [16, 3] == [] |> rex(3 ~> 2 ~> 8 ~> mult)
  end

  test "can call partial function" do
    assert [24, 4] == [] |> rex(4 ~> 8 ~> triple)
  end

  test "can apply kernel function directly" do
    assert [3] == [] |> rex(1 ~> 2 ~> Kernel.+/2)
  end

  test "can push function reference to stack" do
    assert [[4, 5], "old"] == ["old"] |> rex(["hola", "mundo"] ~> (&String.length/1) ~> Enum.map/2)
  end

  test "can apply partial refeference" do
    assert [6] == [] |> rex([1, 2, 3] ~> sum)
  end

  test "can apply partial refeference defined in reverse" do
    assert [6] == [] |> rex([1, 2, 3] ~> sumr)
  end

  test "can push local function reference" do
    assert [&Rex.Examples.answer/0] == [] |> rex(&answer/0)
  end

  test "can call remote function with zero arity" do
    assert [42] == [] |> rex(Rex.Examples.answer/0)
  end

  test "can call local function with zero arity" do
    assert [42] == [] |> rex(answer/0)
  end

  test "can call local function with non-zero arity" do
    assert [25] == [5] |> rex(square/1)
  end

  test "show prints the current stack" do
    fun = fn ->
      assert [5] == [5] |> rex(show)
    end
    assert capture_io(fun) == "[5]\n"
  end

  test "quote pushes a Rex program with ~> into the stack" do
    assert [[{:foo, _, _}, 2, 1]] = [] |> rex(quote(1 ~> 2 ~> foo))
  end

  test "quote pushes a Rex program with <~ into the stack" do
    assert [[{:foo, _, _}, 2, 1]] = [] |> rex(quote(foo <~ 2 <~ 1))
  end

  test "unquote executes a quoted program on top of stack with the rest of the stack" do
    assert [5, 4] = [2, 3, 4] |> rex(quote(Kernel.+/2) ~> unquote)
  end

  test "ifte selects if condition is true" do
    assert [:wii] = [] |> rex(ifte <~ true <~ quote(:wii) <~ quote(:woo))
  end

  test "ifte selects if condition is non-true" do
    assert [:woo] = [] |> rex(ifte <~ nil <~ quote(:wii) <~ quote(:woo))
  end

  test "ifte executes with remainding of stack when true" do
    assert [12, 15] = [4, 3, 15] |> rex(ifte <~ true <~ quote(Kernel.*/2) <~ quote(:nop))
  end

  test "unquote can execute a function by binding" do
    assert [12] = [3] |> rex(quote(4 ~> mult) ~> unquote)
  end

  test "ifte can execute a remote rex function" do
    assert [12] = [] |> rex(ifte <~ true <~ quote(Rex.Examples.mult <~ 3 <~ 4) <~ quote(:noop))
  end

  test "ifte can execute a function by binding" do
    assert [12] = [4] |> rex(ifte <~ true <~ quote(mult <~ 3) <~ quote(:noop))
  end

  test "rex can take a do with a line" do
    assert [3, 12, 5] == [3, 4, 5] |> rex(do: swap triple swap)
  end

  test "rex can take a multiline block with one word per line" do
    assert [9] == [] |> (rex do
      1
      2
      Kernel.+/2
      Rex.Examples.triple
    end)
  end

  test "defined function with do performs in order" do
    fun = fn ->
      assert [10, 12] == [4, 5] |> rex(tatata)
    end
    assert capture_io(fun) == "[12, 5]\n"
  end

  test "word with value reference takes values from stack" do
    assert [1, 3, 1, 3, 1, 2, 3] = [1, 2, 3] |> rex(caca)
  end

  test "app calls a function with values from stack" do
    assert ["22"] == [&Kernel.inspect/1, 22] |> rex(app)
  end

  test "app doesnt calls if not enough values on stack" do
    assert [&Kernel.inspect/1] == [&Kernel.inspect/1] |> rex(app)
  end

end

end
