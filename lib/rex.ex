defmodule Rex do

  defmacro __using__(_) do
    quote do
      import Rex
      import Rex.Stack
      import Rex.Control
      import Rex.Math
    end
  end

  import Rex.Core

  @doc ~S"""
  Define a new Rex function.

  You can call `drex` to define a new _word_ that acts either as a
  *stack shuffler* or as *operator on the stack*.

  To define a stack *shuffling* word, the syntax is:

      # (example from `Rex.Stack.swap/1`)
      drex swap(a, b)     (b, a)


  To define a stack *operator* you use the `~>` or `<~` syntax:

      # pushes 1 then 2 then performs adition
      drex three        1 ~> 2 ~> Kernel.+/2

      # pushes 2 then performs multiplication
      # expecting a first value already on stack (ie. partial function)
      drex double       Kernel.*/2 <~ 2


  As *operators* are the most frequent types of words you will be creating,
  the following *concatenative* syntax is supported:

      # This will multiply the second element on the stack
      # and then print the final stack state to stdout.
      drex double_second  swap double swap show

  However, if you want to also push an integer or any other Elixir literal,
  trying something like `3 double` wont work because its not valid Elixir syntax.
  But you can use the `do` notation for `drex`:


       drex thirtysix do
         3
         double dup Kernel.*/2
       end

  is exactly the same as:

       drex thirtysix  3 ~> double ~> dup ~> Kernel.*/2

  The `do` form is peferred for large words. Most likely you'll just want to
  keep them short as concatenative programs are very composable.

  """
  defmacro drex({{name, _, patterns}, _, exprs}) when length(patterns) > 0 do
    rex_def({:def, :shuffler}, {name, patterns, exprs})
  end

  defmacro drex({name, _, [expr]}) do
    rex_def({:def, :operator}, {name, nil, expr}, __CALLER__)
  end

  defmacro drex({name, _, args}, expr = [do: _]) do
    rex_def({:def, :operator}, {name, args, expr}, __CALLER__)
  end

  @doc """
  Compile a Rex expression into an Elixir function.

  The returned anonymous function can be given a stack to operate on.
  """
  defmacro rex(expr) do
    rex_fn(expr, __CALLER__)
  end

  @doc ~S"""
  Pipe an exising stack to a new Rex expression.

      [5, 2, 3] |> rex(double ~> swap ~> double) #=> [4, 10, 3]

  """
  defmacro rex(stack, expr) when is_list(stack) do
    quote do
      unquote(stack) |> unquote(rex_fn(expr, __CALLER__)).()
    end
  end

end

