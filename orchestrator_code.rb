require_relative 'lib/agent'
require_relative 'lib/environment'

require 'json'

# CONFIG
MAX_ROUNDS = 10
LOG_FILE = "code_review_training.jsonl"
PROJECT_ROOT = "./sample_code" #this should be later handled.. idk how for now

env = Environment.new
alpha = Agent.new(name: "Alpha", model_name: "llama3", endpoint: "http://127.0.0.1:11431")
beta = Agent.new(name: "Beta", model_name: "mistral", endpoint: "http://127.0.0.1:11432")

history = []

#run

puts "Env start"

MAX_ROUNDS.times do |i|
  round_num = i + 1
  puts "Round #{round_num}"

  draft = alpha.formulate_code(env.state[:current_task], history)
  puts "Reasoning: #{draft['reasoning']}"

  critique = beta.formulate_review(env.state[:current_tast], draft['code'], history)
  puts "Critique rating #{crititque['rating']}/10"

  final_action = alpha.refine_code(env.state[:current_task], draft['code'], critique['critique'])

  actions = { alpha: final_action, beta: critique }

  result = env.step(actions)

  history << { 
    round: round_num,
    task: env.state[:current_task],
    code: final_action['code'],
    reward: result[:reward]
  }

  history = history.last(3)

  if result[:reward] > 15
    File.open(LOG_FILE, 'a') { |f| f.puts({ state: env.state, actions: actions, result: result})}
    puts "Round saved to training log"
  end

  puts "reward: #{result[:reward]}"
  puts "feedback #{result[:judge_feedback]}"

  if result[:reward] > 18
    puts 'Achieved'
    break
  end
end
