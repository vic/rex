defmodule Rex.ReadmeExamples do

  @moduledoc ~S"""

  ## Examples from README

  iex> # drop: removes the topmost element from the stack
  iex> use Rex
  ...> [1, 2, 3] |> rex(drop)
  [2, 3]

  iex> use Rex
  iex> import Rex.Math
  iex> [4, 5] |> rex(3 ~> 2 ~> 1 ~> add ~> mul ~> swap)
  [4, 9, 5]

  """

  use Rex

end
