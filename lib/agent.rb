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
  
  def formulate_code(task, history)
    prompt = <<~PROMPT
      [TASK] #{task}
      [CONTEXT] You are writing a NEW Ruby implementation. 
      [HISTORY] #{history.inspect}
      [FORMAT] Return ONLY JSON: {"code": "...", "reasoning": "..."}
    PROMPT
    call_llm(prompt)
  end

  def formulate_review(task, alpha_code, history)
    prompt = <<~PROMPT
      [TASK] #{task}
      [CODE TO REVIEW]
      #{alpha_code}
      [CRITERIA] Check for N+1 queries, thread safety, and Ruby idioms.
      [FORMAT] Return ONLY JSON: {"critique": "...", "rating": 1..10}
    PROMPT
    call_llm(prompt)
  end

  def refine_code(task, original_code, critique)
  prompt = <<~PROMPT
      [TASK] #{task}
      [ORIGINAL CODE]
      #{original_code}
      [FEEDBACK FROM PEER]
      #{critique}
      [INSTRUCTION] Improve the code by addressing the feedback. 
      [FORMAT] Return ONLY JSON: {"code": "...", "reasoning": "..."}
    PROMPT
    call_llm(prompt)
  end


  private

  def call_llm(prompt)
    response = @conn.post('/api/generate') do |req|
      req.body = { 
      model: @model_name,
      prompt: prompt,
      stream: false,
      format: 'json',
      options: { temperature: 0.7 }
      }.to_json
    end
  JSON.parse(JSON.parse(response.body)['response'])
  rescue => e 
    { "code" => "", "critique" => "Error: #{e.message}", "reasoning" => "API Failure", "rating" => 0 }
  end
end
