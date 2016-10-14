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

  doctest Rex
  doctest Rex.ReadmeExamples

  use Rex
  import Rex.Examples

  defmacrop rex_data(data, expr) do
    quote do
      {data, _} = {unquote(data), []} |> unquote(Rex.Core.rex_fn(expr, __CALLER__)).()
      data
    end
  end

  test "swap changes topmost two elements on data stack" do
    assert [2, 1, 3] == [1, 2, 3] |> rex_data(swap)
  end

  test "double duplicates topmost value" do
    assert [6, 1] == [3, 1] |> rex_data(double)
  end

  test "can call a sequence of functions" do
    assert [6, 2, 5] == [1, 3, 5] |> rex_data(double ~> swap ~> double)
  end

  test "can place arguments as part of program" do
    assert [6, 2, 5] == [] |> rex_data(5 ~> 3 ~> 1 ~> double ~> swap ~> double)
  end

  test "can use drex to define a name for a program" do
    assert [6, 2, 5] == [] |> rex_data(5 ~> 3 ~> 1 ~> double_swap)
  end

  test "can call to native function reference" do
    assert [16, 3] == [] |> rex_data(3 ~> 2 ~> 8 ~> mult)
  end

  test "can call partial function" do
    assert [24, 4] == [] |> rex_data(4 ~> 8 ~> triple)
  end

  test "can apply kernel function directly" do
    assert [3] == [] |> rex_data(1 ~> 2 ~> Kernel.+/2)
  end

  test "can push function reference to stack" do
    assert [[4, 5], "old"] == ["old"] |> rex_data(["hola", "mundo"] ~> (&String.length/1) ~> Enum.map/2)
  end

  test "can apply partial refeference" do
    assert [6] == [] |> rex_data([1, 2, 3] ~> sum)
  end

  test "can apply partial refeference defined in reverse" do
    assert [6] == [] |> rex_data([1, 2, 3] ~> sumr)
  end

  test "can push local function reference" do
    assert [&Rex.Examples.answer/0] == [] |> rex_data(&answer/0)
  end

  test "can call remote function with zero arity" do
    assert [42] == [] |> rex_data(Rex.Examples.answer/0)
  end

  test "can call local function with zero arity" do
    assert [42] == [] |> rex_data(answer/0)
  end

  test "can call local function with non-zero arity" do
    assert [25] == [5] |> rex_data(square/1)
  end

  test "show prints the current stack" do
    fun = fn ->
      assert [5] == [5] |> rex_data(show)
    end
    assert capture_io(fun) == "[5]\n"
  end

  test "quote pushes the elixir ast without changing it into the stack" do
    assert [{{:~>, _, [{:~>, _, [1, 2]}, {:foo, _, nil}]}, _env}] = [] |> rex_data(@[1 ~> 2 ~> foo])
  end

  test "quote pushes the definition environment alongide the quoted code" do
    assert [{code, env}] = [] |> rex_data(@[1 + 2])
    assert {3, _} = Code.eval_quoted(code, [], env)
  end

  test "dequote executes a quoted program on top of stack with the rest of the stack" do
    assert [5, 4] = [2, 3, 4] |> rex_data(@[Kernel.+/2] ~> dequote)
  end

  test "ifte selects if condition is true" do
    assert [:wii] = [] |> rex_data(ifte <~ true <~ @[:wii] <~ @[:woo])
  end

  test "ifte selects if condition is non-true" do
    assert [:woo] = [] |> rex_data(ifte <~ nil <~ @[:wii] <~ @[:woo])
  end

  test "ifte executes with remainding of stack when true" do
    assert [12, 15] = [4, 3, 15] |> rex_data(ifte <~ true <~ @[Kernel.*/2] <~ @[:nop])
  end

  test "dequote can execute a function by binding" do
    assert [12] = [3] |> rex_data(@[4 ~> mult] ~> dequote)
  end

  test "ifte can execute a remote rex function" do
    require Rex.Macro
    assert [12] = [] |> rex_data(ifte <~ true <~ @[Rex.Examples.mult <~ 3 <~ 4] <~ @[:noop])
  end

  test "ifte can execute a function by binding" do
    assert [12] = [4] |> rex_data(ifte <~ true <~ @[mult <~ 3] <~ [:noop])
  end

  test "rex can take a do with a line" do
    assert [4, 18, 5] == [3, 4, 5] |> rex_data(do: double triple swap)
  end

  test "rex can take a multiline block with one word per line" do
    assert [9] == [] |> (rex_data do
      1
      2
      Kernel.+/2
      Rex.Examples.triple
    end)
  end

  test "defined function with do performs in order" do
    fun = fn ->
      assert [10, 12] == [4, 5] |> rex_data(tatata)
    end
    assert capture_io(fun) == "[12, 5]\n"
  end

  test "word with value reference takes values from stack" do
    assert [1, 3, 1, 3, 1, 2, 3] = [1, 2, 3] |> rex_data(caca)
  end

  test "app calls a function with values from stack" do
    assert ["22"] == [&Kernel.inspect/1, 22] |> rex_data(app)
  end

  test "app doesnt calls if not enough values on stack" do
    x = fn ->
      [&Kernel.inspect/1] |> rex_data(app)
    end
    assert_raise FunctionClauseError, x
  end

  test "can execute a function specifying its arity" do
    assert [6] == [] |> rex_data([1, 2, 3] ~> (&Kernel.+/2) ~> Enum.reduce/2)
  end

  test "calling Elixir quote doesnt modify the ast" do
    assert [{:quote, _, [[do: {:+, _, [1, 2]}]]}] = [] |> rex_data(quote(do: 1 + 2))
  end

end

