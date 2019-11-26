require "test_helper"

class TodoOrDieTest < UnitTest
  def test_not_due_todo_does_nothing
    Timecop.travel(Date.civil(2200, 2, 3))

    TodoOrDie("Fix stuff", by: Date.civil(2200, 2, 4))

    # 🦗 sounds
  end

  def test_due_todo_blows_up
    Timecop.travel(Date.civil(2200, 2, 4))

    error = assert_raises(TodoOrDie::OverdueTodo) {
      TodoOrDie("Fix stuff", by: Date.civil(2200, 2, 4))
    }

    assert_equal <<~MSG, error.message
      TODO: "Fix stuff" came due on 2200-02-04. Do it!
    MSG
  end

  def test_config_custom_explosion
    Timecop.travel(Date.civil(2200, 2, 5))
    actual_message, actual_by = nil
    TodoOrDie.config(
      die: ->(message, by) {
        actual_message = message
        actual_by = by
        "pants"
      }
    )
    some_time = Time.parse("2200-02-04")

    result = TodoOrDie("kaka", by: some_time)

    assert_equal result, "pants"
    assert_equal actual_message, "kaka"
    assert_equal actual_by, some_time
  end

  def test_config_and_reset
    some_lambda = -> {}
    TodoOrDie.config(die: some_lambda)

    assert_equal TodoOrDie.config[:die], some_lambda
    assert_equal TodoOrDie.config({})[:die], some_lambda

    TodoOrDie.reset

    assert_equal TodoOrDie.config[:die], TodoOrDie::DEFAULT_CONFIG[:die]
  end

  def test_when_rails_is_a_thing_and_not_production
    make_it_be_rails(false)

    Timecop.travel(Date.civil(1980, 1, 20))

    assert_raises(TodoOrDie::OverdueTodo) {
      TodoOrDie("I am in Rails", by: Date.civil(1980, 1, 15))
    }
  end

  def test_when_rails_is_a_thing_and_is_production
    faux_logger = make_it_be_rails(true)

    Timecop.travel(Date.civil(1980, 1, 20))

    TodoOrDie("Solve the Iranian hostage crisis", by: Date.civil(1980, 1, 20))

    assert_equal <<~MSG, faux_logger.warning
      TODO: "Solve the Iranian hostage crisis" came due on 1980-01-20. Do it!
    MSG
  end

  def test_todo_or_die_file_path_removed_from_backtrace
    Timecop.travel(Date.civil(2200, 2, 4))

    error = assert_raises(TodoOrDie::OverdueTodo) {
      TodoOrDie("Fix stuff", by: Date.civil(2200, 2, 4))
    }

    assert_empty(error.backtrace.select { |line| line.match?(/todo_or_die\.rb/) })
  end

  def test_has_version
    assert TodoOrDie::VERSION
  end

  def test_by_string_due_blows_up
    Timecop.travel(Date.civil(2200, 2, 4))

    assert_raises(TodoOrDie::OverdueTodo) {
      TodoOrDie("Feelin' stringy", by: "2200-02-04")
    }
  end

  def test_by_string_not_due_does_not_blow_up
    Timecop.travel(Date.civil(2100, 2, 4))

    TodoOrDie("Feelin' stringy", by: "2200-02-04")

    # 🦗 sounds
  end

  def test_due_and_if_condition_is_true_blows_up
    Timecop.travel(Date.civil(2200, 2, 4))

    assert_raises(TodoOrDie::OverdueTodo) {
      TodoOrDie("Check your math", by: Date.civil(2200, 2, 4), if: -> { 2 + 2 == 4 })
    }
  end

  def test_not_due_and_if_condition_is_true_does_not_blow_up
    Timecop.travel(Date.civil(2100, 2, 4))

    TodoOrDie("Check your math", by: Date.civil(2200, 2, 4), if: -> { 2 + 2 == 4 })

    # 🦗 sounds
  end

  def test_due_and_if_condition_is_false_does_not_blow_up
    Timecop.travel(Date.civil(2200, 2, 4))

    TodoOrDie("Check your math", by: Date.civil(2200, 2, 4), if: -> { 2 + 2 == 5 })

    # 🦗 sounds
  end

  def test_by_not_passed_and_if_condition_is_true_blows_up
    error = assert_raises(TodoOrDie::OverdueTodo) {
      TodoOrDie("Check your math", if: -> { 2 + 2 == 4 })
    }

    assert_equal <<~MSG, error.message
      TODO: "Check your math" has met the conditions to be acted upon. Do it!
    MSG
  end

  def test_by_not_passed_and_if_condition_false_does_not_blow_up
    TodoOrDie("Check your math", if: -> { 2 + 2 == 5 })

    # 🦗 sounds
  end

  def test_by_not_passed_and_if_condition_is_false_boolean_does_not_blow_up
    TodoOrDie("Check your math", if: false)

    # 🦗 sounds
  end

  def test_by_not_passed_and_if_condition_is_true_boolean_blows_up
    assert_raises(TodoOrDie::OverdueTodo) {
      TodoOrDie("Check your math", if: true)
    }
  end
end
