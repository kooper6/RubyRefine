require 'json'
require 'faraday'

class Judge
  def initializer(endpoint: "http://127.0.0.1:11431")
    @endpoint = endpoint
    @model = "llama3.1"
    @conn = Faraday.new(url: endpoint) { |f| f.request :json; f.adapter Faraday.default_adapter }
  end

  def rate_collaboration(actions)
    prompt = construct_judge_prompt(actions)

    response = @conn.post('/api/generate', { 
      model: @model,
      prompt: prompt,
      stream: false,
      format: "json",
      options: { temperature: 0.2 }
    }).to_json

    parse_score(response.body)
  end

  def evaluate_work(actions, task)
    prompt = <<~PROMPT
      [ROLE] Senior Ruby Architect.
      [TASK] #{task}
      [IMPLEMENTATION] #{actions[:alpha]['code']}
      [CRITIQUE GIVEN] #{actions[:beta]['critique']}
      
      [GOAL] 
      1. Rate the implementation (0.0 - 1.0).
      2. Did Alpha address Beta's specific feedback?
      3. Is the code technically sound?
      
      [FORMAT] Return ONLY JSON: {"score": 0.9, "feedback": "Brief technical summary"}
    PROMPT
    response = @conn.post('/api/generate') do |req|
      req.body = {
        model: @model,
        prompt: prompt,
        stream: false,
        format: 'json',
        options: { temperature: 0.2 } # Keep the judge consistent
      }.to_json
    end

    JSON.parse(JSON.parse(response.body)['response'])
  rescue
    { "score" => 0.5, "feedback" => "Judge failed to parse." }
  end

  private

  def construct_judge_prompt(actions)
    <<~PROMPT
      [SYSTEM]
      You are an expert AI evaluator. Rate the coordination quality of two agents.
      The goal was to choose numbers that sum to 10.
      
      AGENT ALPHA: Move=#{actions[:alpha]['move']}, Reasoning="#{actions[:alpha]['reasoning']}"
      AGENT BETA: Move=#{actions[:beta]['move']}, Reasoning="#{actions[:beta]['reasoning']}"
      
      [CRITERIA]
      1. Logical consistency: Does the reasoning explain the move?
      2. Coordination: Did they attempt to adapt based on previous rounds?
      3. Zero-Avoidance: Did they follow the rule to not pick 0?

      [OUTPUT]
      Return ONLY a JSON object with a score between 0.0 and 1.0.
      Example: {"score": 0.85}
    PROMPT
  end

  def parse_score(body)
    raw_output = JSON.parse(body)['response']
    parsed = JSON.parse(raw_output)
    score = parsed['score'].to_f

    [[score, 0.1].max, 1.0].min
  rescue
    0.5
  end
end
