require_relative 'lib/agent'
require_relative 'lib/environment'

require 'json'

# CONFIG

ROUNDS = 20
TARGET_SUM = 10
LOG_FILE = "fine_tune_data.jsonl"

env = Environment.new(target_sym: TARGET_SUM)

agents = { 
  alpha: Agent.new(name: "Alpha", model_name: "llama3", endpoint: "http://127.0.0.1:11431"),
  beta: Agent.new(name: "Beta", model_name: "mistral", endpoint: "http://127.0.0.1:11432")
}

history = []

ROUNDS.times do |i|
  current_round = i + 1

  actions = { 
    alpha: agents[:alpha].formulate_action(env.state, history),
    beta: agents[:beta].formulate_action(env.state, history)
  }

  result = env.step(actions)

  record = { 
    round: current_round,
    state: env.state,
    actions: actions,
    reward: result[:reward],
    quality: result[:quality],
    sum: result[:sum]
  }

  history << record
  
  if result[:reward] > 20
    File.open(LOG_FILE, 'a') { |f| f.puts records.to_json }
  end

  puts "Round: #{current_round} | reward #{result[:reward]}"
  puts "sum #{resuts[:sum]}, quality #{results[:quality]}"

  puts "Alpha [#{actions[:alpha]['move']}] - #{actions[:alpha]['reasoning']}"
  puts "Beta [#{actions[:beta]['move']}] - #{actions[:beta]['reasoning']}"

end

puts "Done"


