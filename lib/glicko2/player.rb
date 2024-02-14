# frozen_string_literal: true

module Glicko2
  class Player
    attr_accessor :vol

    TAU = 0.5 # The system constant, which constrains the change in volatility over time.

    # 追加定数
    # COEFF173 = 173.7178
    COEFF173 = 400 / Math.log(10)

    # 原版から名称変更した変数
    # 関数 v との重複を避けるため変数 v → vv
    # Glicko1 scale の rating → @rating_
    # Glicko1 scale の RD → @rd_

    def get_rating
      (@rating_ * COEFF173) + 1500
    end

    def set_rating(rating)
      @rating_ = (rating - 1500) / COEFF173
    end

    def get_rd
      @rd_ * COEFF173
    end

    def set_rd(rd)
      @rd_ = rd / COEFF173
    end

    # @param rating [Float]
    # @param rd     [Float]
    # @param vol    [Float]
    def initialize(rating: 1500, rd: 350, vol: 0.06)
      # For testing purposes, preload the values
      # assigned to an unrated player.
      set_rating(rating)
      set_rd(rd)
      @vol = vol
    end

    # Calculates and updates the player's rating deviation for the beginning of a rating period.
    def pre_rating_rd
      set_rd(Math.sqrt((get_rd**2) + (@vol**2)))
    end

    # Calculates the new rating and rating deviation of the player.
    # @param rating_list  [Array]
    # @param rd_list      [Array]
    # @param outcome_list [Array]
    def update_player(rating_list, rd_list, outcome_list)
      # Convert the rating and rating deviation values for internal use.
      rating_conv = rating_list.map do |x|
        (x - 1500) / COEFF173
      end

      rd_conv = rd_list.map do |x|
        x / COEFF173
      end
      vv = v(rating_conv, rd_conv)
      @vol = new_vol(rating_conv, rd_conv, outcome_list, vv)
      pre_rating_rd

      #      set_rd(1 / Math.sqrt((1 / get_rd**2) + (1 / vv)))
      @rd_ = (1 / Math.sqrt((1 / (@rd_**2)) + (1 / vv)))

      temp_sum = 0

      rating_conv.size.times do |i|
        temp_sum += g(rd_conv[i]) * (outcome_list[i] - e(rating_conv[i], rd_conv[i]))
      end

      set_rating(get_rating + ((get_rd**2) * temp_sum))
    end

    # Calculating the new volatility as per the Glicko2 system.
    # @param rating_list  [Array]
    # @param rd_list      [Array]
    # @param outcome_list [Array]
    # @return [Float]
    def new_vol(rating_list, rd_list, outcome_list, vv)
      # step 1
      a = Math.log(@vol**2)
      eps = 0.000001
      aa = a

      # step 2
      bb = nil
      @delta = delta(rating_list, rd_list, outcome_list, vv)
      if (@delta**2) > ((get_rd**2) + vv)
        bb = Math.log((@delta**2) - (get_rd**2) - vv)
      else
        k = 1
        k += 1 while f(a - (k * Math.sqrt(TAU**2)), @delta, vv, a).negative?
        bb = a - (k * Math.sqrt(TAU**2))
      end

      # step 3
      fa = f(aa, @delta, vv, a)
      fb = f(bb, @delta, vv, a)

      # step 4
      while (bb - aa).abs > eps
        # a
        cc = aa + (((aa - bb) * fa) / (fb - fa))
        fc = f(cc, @delta, vv, a)

        # b
        if fc * fb <= 0
          aa = bb
          fa = fb
        else
          fa /= 2.0
        end

        # c
        bb = cc
        fb = fc
      end

      # step 5
      Math.exp(aa / 2)
    end

    def f(x, delta, vv, a)
      ex = Math.exp(x)
      num1 = ex * ((delta**2) - (get_rating**2) - vv - ex)
      denom1 = 2 * (((get_rating**2) + vv + ex)**2)
      (num1 / denom1) - ((x - a) / (TAU**2))
    end

    # The delta function of the Glicko2 system.
    # @param rating_list  [Array]
    # @param rd_list      [Array]
    # @param outcome_list [Array]
    # @param vv            [Float]
    # @return [Float]
    def delta(rating_list, rd_list, outcome_list, vv)
      temp_sum = 0
      rating_list.size.times do |i|
        temp_sum += g(rd_list[i]) * (outcome_list[i] - e(rating_list[i], rd_list[i]))
      end
      vv * temp_sum
    end

    # The v function of the Glicko2 system.
    # @param rating_list [Array]
    # @param rd_list     [Array]
    # @return [Float]
    def v(rating_list, rd_list)
      temp_sum = 0
      rating_list.size.times do |i|
        temp_e = e(rating_list[i], rd_list[i])
        temp_sum += (g(rd_list[i])**2) * temp_e * (1 - temp_e)
      end
      1 / temp_sum
    end

    # The Glicko E function.
    # @return [Float]
    def e(p2rating, p2rd)
      1 / (1 + Math.exp(-1 * g(p2rd) * (@rating_ - p2rating)))
    end

    # The Glicko2 g(RD) function.
    # @return [Float]
    def g(rd)
      1 / Math.sqrt(1 + (3 * (rd**2) / (Math::PI**2)))
    end

    # Applies Step 6 of the algorithm. Use this for players who did not compete in the rating period.
    def did_not_compete
      pre_rating_rd
    end
  end
end
