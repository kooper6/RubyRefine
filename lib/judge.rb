require 'json'
require 'faraday'

class Judge
  def initializer(endpoint:)
    @conn = Faraday.new(url: endpoint) { |f| f.request :json; f.adapter Faraday.default_adapter }
  end

  def evaluate_collaboration(move_a, reason_a, move_b, reason_b)
    prompt = <<~PROMPT
      Two agents are playing a game to sum to 10.
      Agent A chose #{move_a} because: "#{reason_a}"
      Agent B chose #{move_b} because: "#{reason_b}"

      Rate their collaboration from 0 to 1
      Did they try to adapt to each other?
      Return ONLY a JSON number, exam0ple : {"score": 0.85}
    PROMPT

    response = @conn.post('/api/generate', { 
      model: "llama3.1",
      prompt: prompt,
      stream: false,
      format: "json"
    }).to_json

    JSON.parse(JSON.parse(response.body)['response]'])['score']
  rescue
    0.5
  end
end
