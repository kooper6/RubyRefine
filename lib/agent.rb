require 'faraday'
require 'json'

class Agent
  attr_reader :name, :model_name

  def initialize(name:, model_name:, endpoint:)
    @name = name
    @model_name = model_name
    @conn = Faraday.new(url: endpoint)
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
