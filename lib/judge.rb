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
