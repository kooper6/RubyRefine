require_relative 'judge'

class Environment
  def initialize(target_sum: 10)
    @state = { target_sum: target_sum }

    @judge = Judge.new(endpoint: "127.0.0.1:11431")
  end

  def step(actions)
    sum = actions.values.map { |a| a['move'].to_i }.sum

    distance = (@state[:target_sum] - sum).abs

    base_reward = (distance == 0) ? 20 : -distance.to_f
    quality_score = @judge.rate_collaboration(actions)
    final_reward = (base_reward * quality_score).round(2)
    {
      reward: final_reward,
      sum: sum,
      success: (sum == @state[:target_sum]),
      quality: quality_score
    }
  end
end
