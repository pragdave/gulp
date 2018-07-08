defmodule Gulp.Config do


  @moduledoc """
  Support the creation of hierarchies of structs.

  A base module could do something such as:

  ~~~ elixir
  defmodule Base do
    @fields [
      { :name, required: true },
      { :age,  default: 21 },
    ]

    use Gulp.Config(@fields)
  ~~~

  the resulting module would contain the structure with name and age fields.

  Another module can create a config that is a superset of these fields by
  referencing the Base module:

  ~~~ elixir
  defmodule Derived do
    @fields [
      { :height, default: 1.65  },
      { :weight, required: true },
      Base
    ]

    use Gulp.Config(@fields)
  ~~~

  This would define a structure with 4 fields (name, age, height, and weight).

  These derived structures are flat. They do not contain a reference to the base
  structure; instead they simply contain fields of the same names and attributes.
  """

  defmacro __using__(options) do

    fields   = options[:fields] || raise "Missing option `fields:`"

    based_on = case options[:based_on] do
       nil -> nil
       module -> Code.eval_quoted(module, __CALLER__.vars) |> elem(0)
    end

    all_fields = Map.merge(fields_of_parent(based_on), fields_as_map(fields))

    caller = __CALLER__.module
    me     = __MODULE__

    quote do
      def new(values \\ []) do
        { unquote(Macro.escape(all_fields)), values }
        |> unquote(me).validate_fields(unquote(caller))
        |> unquote(me).build_map()
      end

      def __original_config_options__() do
        unquote(Macro.escape(all_fields))
      end
    end
  end



  #------------------------------------------------------+
  #  Converting a field definition into a prototype map  |
  #------------------------------------------------------+

  def fields_as_map(fields) do
    fields
    |> Enum.map(&field_definition/1)
    |> List.flatten
    |> Enum.into(%{})
  end

  defp field_definition({ name, options }) do
    { name, options[:default] || :__required__ }
  end

  defp fields_of_parent(nil), do: %{}
  defp fields_of_parent(module) when is_atom(module) do
    module.__original_config_options__()
  end

  #--------------------+
  #  Field validation  |
  #--------------------+

  def validate_fields({ fields, values }, caller) do

    value_keys = Keyword.keys(values)

    required = fields
               |> Enum.filter(fn
                    { _name, :__required__ } -> true
                    { _name, _default      } -> false
                  end)
               |> Enum.map(&elem(&1, 0))

    case required -- value_keys do
      []      -> nil
      missing ->
        raise """
        \n\nThe code called:

        #{caller}.new(#{inspect(values)})

        This call is missing the required keys: #{inspect(missing)}
        """
    end

    allowed = fields |> Enum.map(&elem(&1, 0))

    case value_keys -- allowed do
      [] -> nil
      extra ->
        raise """
        \n\nThe code called:

        #{caller}.new(#{inspect(values)})

        This call has the unsupported key(s): #{inspect extra}
        """
    end
    { fields, values }
  end

  #-------------------------------------------------------------------------+
  #  Build a resulting map based on the prototype and the passed-in values  |
  #-------------------------------------------------------------------------+

  def build_map({ fields, values }) do
    Map.merge(fields, Enum.into(values, %{}))
  end

end
