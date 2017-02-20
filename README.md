# Rex - Concatenative elixir macro language.

<a href="https://travis-ci.org/vic/rex"><img src="https://travis-ci.org/vic/rex.svg"></a>
[![help maintain this lib](https://img.shields.io/badge/looking%20for%20maintainer-DM%20%40vborja-663399.svg)](https://twitter.com/vborja)


![rex](https://cloud.githubusercontent.com/assets/331/19221774/310460ee-8e0f-11e6-864b-0a4f2c34b5b2.png)

Rex is a [concatenative language](http://concatenative.org) built with Elixir macros.

Being powered by Elixir macros means that Rex has no parser of its own as it just
uses valid Elixir syntax and thus can be embedded on any elixir program.

## Installation

[Available in Hex](https://hex.pm/packages/rex), the package can be installed as:

  1. Add `rex` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:rex, "~> 0.1.0"}]
    end
    ```

## Stack based

Rex is stack based, that is all Rex functions take a list and return another list.

The topmost element in a stack is the one at index zero, for example, for
`[1, 2, 3]` the top of the stack is `1`. Most Rex functions will operate on
top-most elements as they need and then push the result back to the top.


Inside the `rex` macro, the `~>` operator indicates the order in which to push
values or operators on to the top of the stack.

For example, `rex(1 ~> 2 ~> add)` would result on the following 
`[add, 2, 1]` stack that when executed will yield `[3]`.

So the `~>` allows post-fix notation (operands first, operator last) syntax.
This is the preferred way as most concatenative languages are postfix, but
Rex also has a `<~` operator which just pushes values in the reverse order:
`rex(add <~ 2 <~ 1)` will result on `[add, 2, 1]`.


The following example uses functions from `Rex.Core` for stack manipulation
and `Rex.Math` that defines aliases to standard elixir math operators.

```elixir
iex> [4, 5] |> rex(3 ~> 2 ~> 1 ~> add ~> mul ~> swap)
[4, 9, 5] 
```

More examples available as [tests](https://github.com/vic/rex/blob/master/test/rex_test.exs)

## Words

In concatenative languages, functions are refered to as *words*.

Inside an Elixir module, once you have `include Rex`'d
you can call `drex` to define a new _word_ that acts either as a
*stack shuffler* or as an *operator on the stack*.

To define a stack *shuffling* word, the syntax is:

```elixir
    # (example from `Rex.Stack.swap/1`)
    drex swap(a, b)     (b, a)
```


To define a stack *operator* you use the `~>` or `<~` syntax:

```elixir
    # pushes 1 then 2 then performs adition
    drex three        1 ~> 2 ~> Kernel.+/2

    # pushes 2 then performs multiplication
    # expecting a first value already on stack (ie. partial function)
    drex double       Kernel.*/2 <~ 2
```


As *operators* are the most frequent types of words you will be creating,
the following *concatenative* syntax is supported:

```elixir
    # This will multiply the second element on the stack
    # and then print the final stack state to stdout.
    drex double_second  swap double swap show
```

However, if you want to also push an integer or any other Elixir literal,
trying something like `3 double` wont work because its not valid Elixir syntax.
But you can use the `do` notation for `drex`:


```elixir
      drex sixsix do
        3
        double dup Kernel.*/2
      end
```

is exactly the same as:

```elixir
      drex sixsix  3 ~> double ~> dup ~> Kernel.*/2
```

The `do` form is peferred for large words. Most likely you'll just want to
keep them short as concatenative programs are very composable.

#### [Pointless programming](https://en.wikipedia.org/wiki/Tacit_programming)

With Rex you can write point-free functions.

```elixir
drex sumr     List.foldr/3 <~ (&Kernel.+/2) <~ 0

assert [6] == sumr([1, 2, 3])
```

