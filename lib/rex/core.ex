defmodule Rex.Core do

  def rex_def(_, _), do: nil
  def rex_def(_, _, _), do: nil
  def rex_fn(_, _), do: nil

  def run(state = {_, [], _}), do: state
  def run(state) do
    state |> run_top |> run
  end

  def run_top({data, [top | program], env}) do
    top.({data, program, env})
  end

end

