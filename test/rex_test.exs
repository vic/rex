defmodule RexTest.Examples do
  use Rex

  drex double(a)     (a * 2)
  drex double_swap   double ~> swap ~> double
  drex mult          Kernel.*/2
  drex triple        3 ~> mult
  drex puts          IO.puts/1 ~> drop
  drex sum           0 ~> (&Kernel.+/2) ~> List.foldr/3
  drex sumr          List.foldr/3 <~ (&Kernel.+/2) <~ 0

end

defmodule RexTest do
  use ExUnit.Case

  use Rex
  doctest Rex

  alias __MODULE__.Examples, as: E

  test "swap changes topmost two elements on data stack" do
    assert [2, 1, 3] == swap([1, 2, 3])
  end

  test "double duplicates topmost value" do
    assert [6, 1] == E.double([3, 1])
  end

  test "can call Foo.swap with rex" do
    assert [2, 1, 3] == [1, 2, 3] |> rex(swap)
  end

  test "can call a sequence of functions" do
    assert [6, 2, 5] == [1, 3, 5] |> rex(E.double ~> swap ~> E.double)
  end

  test "can place arguments as part of program" do
    assert [6, 2, 5] == [] |> rex(5 ~> 3 ~> 1 ~> E.double ~> swap ~> E.double)
  end

  test "can use drex to define a name for a program" do
    assert [6, 2, 5] == [] |> rex(5 ~> 3 ~> 1 ~> E.double_swap)
  end

  test "can call to native function reference" do
    assert [16, 3] == [] |> rex(3 ~> 2 ~> 8 ~> E.mult)
  end

  test "can call partial function" do
    assert [24, 4] == [] |> rex(4 ~> 8 ~> E.triple)
  end

  test "can apply kernel function directly" do
    assert [3] == [] |> rex(1 ~> 2 ~> Kernel.+/2)
  end

  test "can push function reference to stack" do
    assert [[4, 5], "old"] == ["old"] |> rex(["hola", "mundo"] ~> (&String.length/1) ~> Enum.map/2)
  end

  test "can apply partial refeference" do
    assert [6] == [] |> rex([1, 2, 3] ~> E.sum)
  end

  test "can apply partial refeference defined in reverse" do
    assert [6] == [] |> rex([1, 2, 3] ~> E.sumr)
  end

end
