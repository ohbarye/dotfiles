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

class StatsDistributionTest < Minitest::Test
  def test_percentile_interpolates_linearly
    values = [1, 2, 3, 4, 5]
    assert_in_delta 4.0, Stats.percentile(values, 0.75), 0.001
    assert_in_delta 4.6, Stats.percentile(values, 0.9), 0.001
    assert_in_delta 3.0, Stats.percentile(values, 0.5), 0.001
  end

  def test_percentile_ignores_input_order
    assert_in_delta 4.0, Stats.percentile([5, 1, 4, 2, 3], 0.75), 0.001
  end

  def test_percentile_of_single_value
    assert_in_delta 7.0, Stats.percentile([7], 0.9), 0.001
  end

  def test_percentile_of_empty_is_nil
    assert_nil Stats.percentile([], 0.75)
  end

  def test_share_within_is_inclusive_of_threshold
    assert_in_delta 0.75, Stats.share_within([1, 6, 6.0, 7], 6), 0.001
  end

  def test_share_within_of_empty_is_nil
    assert_nil Stats.share_within([], 6)
  end
end
