require 'faraday'
require 'json'

class Agent
  attr_reader :name, :model_name

  def initialize(name:, model_name:, endpoint:)
    @name = name
    @model_name = model_name
    @conn = Faraday.new(url: endpoint)
  end

  def formulate_action(current_state, history)
    prompt = construct_prompt(current_state, history)
  
    response = @conn.post('/api/generate') do |req|
      req.body = {
        model: @model_name,
        prompt: prompt,
        stream: false,
        format: 'json',
        keep_alive: "24h",
        options: { temperature: 0.7, num_thread: 4 }
      }.to_json
    end
    
    raw_output = JSON.parse(response.body)['response']

    json_match = raw_output.match(/\{.*}/m)

  if json_match
    parsed = JSON.parse(json_match[0])
    move = parsed['move'].to_i
    
    move = rand(1..9) if move == 0 

    reason = parsed['reasoning'] || parsed['reason'] || "No reasoning given"

    {"move" => move, "reason" => reason}
  else
    raise "No valig JSON found"   
  end
  rescue => e 
    { "move" => rand(1..9), "reasoning" => "error: #{e.message}"}
  end

  private

  def construct_prompt(state, history)
    context = history.last(5).map do |h|
      "Round #{h[:round]} : Move #{h[:actions][@name]['move']} | Reward #{h[:reward]}"
    end.join("\n")

    <<~PROMPT
    [INST]
    SYSTEM: You are a player in a coordination game. 
    GOAL: You and the other player must choose numbers that sum to exactly #{state[:target_sum]}.
    IMPORTANT: Do not choose 0. Choose a number between 1 and 9.
    
    HISTORY: #{history.last(3).inspect}
    
    If the previous reward was negative, try a DIFFERENT number this time.
    RESPONSE FORMAT: You must return ONLY valid JSON.
    Example: {"move": 5, "reason": "I am trying to coordinate."}
    [/INST]
  PROMPT

  end
end
