# frozen_string_literal: true

RSpec.describe Glicko2::Player do
  before do
    # Feb222012 example.
    @p1 = described_class.new
    @p1.set_rd(200)
    @p1.update_player([1400, 1550, 1700], [30, 100, 300], [1, 0, 0])
    # Original Ryan example.
    @ryan = described_class.new
    @ryan.update_player([1400, 1550, 1700], [30, 100, 300], [1, 0, 0])
  end

  it "rating" do
    expect(@p1.get_rating - 1464.05).to be <= 0.01
  end

  it "rating deviation" do
    expect(@p1.get_rd - 151.52).to be <= 0.01
  end

  it "volatility" do
    expect(@p1.vol - 0.05999).to be <= 0.00001
  end

  it "Ryan rating" do
    expect(@ryan.get_rating - 1441.53).to be <= 0.01
  end

  it "Ryan rating deviation" do
    expect(@ryan.get_rd - 193.23).to be <= 0.01
  end

  it "Ryan volatility" do
    expect(@ryan.vol - 0.05999).to be <= 0.00001
  end
end
