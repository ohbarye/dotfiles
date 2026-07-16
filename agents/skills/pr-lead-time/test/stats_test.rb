require_relative "test_helper"

class StatsTest < Minitest::Test
  def test_median_odd_count
    assert_in_delta 3.0, Stats.median([5, 1, 3, 2, 4]), 0.001
  end

  def test_median_even_count
    assert_in_delta 2.5, Stats.median([1, 2, 3, 4]), 0.001
  end

  def test_median_of_empty_is_nil
    assert_nil Stats.median([])
  end

  def test_mean
    assert_in_delta 2.5, Stats.mean([1, 2, 3, 4]), 0.001
  end

  def test_mean_of_empty_is_nil
    assert_nil Stats.mean([])
  end
end
