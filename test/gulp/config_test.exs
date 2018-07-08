defmodule Test.Gulp.Config do
  use ExUnit.Case

  defmodule A do
    use Gulp.Config,
        fields: [
          { :one, default: 1 },
          { :two, required: true }
        ]
  end

  defmodule B do

    use Gulp.Config,
        fields: [
          { :three, default: 3 },
          { :four, required: true },
        ],
        based_on: Test.Gulp.Config.A
  end

  test "basic structure created" do
    a = A.new(one: 11, two: 22)

    fields = Map.keys(a)

    assert :one in fields
    assert :two in fields
    assert a.one == 11
    assert a.two == 22
  end


  test "inherited structure created" do
    b = B.new(one: 11, two: 22, three: 33, four: 44)

    fields = Map.keys(b)

    assert :one   in fields
    assert :two   in fields
    assert :three in fields
    assert :four  in fields

    assert b.one   == 11
    assert b.two   == 22
    assert b.three == 33
    assert b.four  == 44
  end

  test "error is thrown if unknown config key passed" do
   assert_raise(RuntimeError, ~r/unsupported key.+wombat/s, fn ->
      Code.compile_string """
      Test.Gulp.Config.A.new(one: 11, two: 22, wombat: 99)
      """
   end)
  end

  test "error is thrown if required key is missing" do
    assert_raise(RuntimeError, ~r/required keys.+:two/s, fn ->
       Code.compile_string """
       Test.Gulp.Config.A.new()
       """
    end)
   end

  test "error is thrown if required key of parent is missing" do
    assert_raise(RuntimeError, ~r/required keys.+:two/s, fn ->
       Code.compile_string """
       Test.Gulp.Config.B.new(four: 123)
       """
    end)
   end

  test "defaults are supplied" do
    a = Test.Gulp.Config.B.new(two: 321, four: 123)

    assert a.one   == 1
    assert a.two   == 321
    assert a.three == 3
    assert a.four  == 123
   end
end
