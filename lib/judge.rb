require 'json'
require 'faraday'

class Judge
  def initializer(endpoint: "http://127.0.0.1:11431")
    @endpoint = endpoint
    @model = "llama3.1"
    @conn = Faraday.new(url: endpoint) { |f| f.request :json; f.adapter Faraday.default_adapter }
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
end
