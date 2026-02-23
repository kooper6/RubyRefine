require_relative 'lib/agent'
require_relative 'lib/replay_buffer'

class MARLOrchestrator
  def initialize(agents)
    @agents = agents
    @buffer = ReplayBuffer.new
    @history = []
    @state = { round: 1, target_sum: 10}
  end
 
  def run_iteration
    current_actions = {}
    @agents.each { |a| current_actions[a.name] = a.formulate_action(@state, @history) }

    reward = calculate_reward(current_actions)

    round_data = { 
      round: @state[:round],
      state: @state.dup,
      actions: current_actions,
      reward: reward,
      history_summary: @history.last(3)
    }

    @history << round_data
    @buffer.save(round_data)

    @state[:round] += 1

    puts "Round: #{round_data[:round]} | Reward: #{reward} | Actions: #{current_actions.values.map{|v| v['move']}}"
    current_actions.each do |name, res|
      puts " #{name}: Move=#{res['move']} | Reason #{res['reason']}}"
    end
  end

  private 

  def calculate_reward(actions)
    sum = actions.values.map { |a| a['move'].to_i }.sum
    sum == @state[:target_sum] ? 20 : -2
  end
end

llama = Agent.new(name: "Alpha", model_name: "llama3", endpoint: "http://localhost:11431")
mistral = Agent.new(name: "Beta", model_name: "mistral", endpoint: "http://localhost:11432")

orchestrator = MARLOrchestrator.new([llama, mistral])

10.times { orchestrator.run_iteration }
