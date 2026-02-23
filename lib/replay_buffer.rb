require 'json'

class ReplayBuffer
  def initialize(file_path = "training_data.jsonl")
    @file_path = file_path
  end

  def save(round_data)
    return unless round_data[:reward] > 0

    File.open(@file_path, "a") do |f|
      training_entry = {  
        insruction: "State: #{round_data[:state].to_json}. Choose the best move.",
        context: round_data[:history_summary],
        response: round_data[:actions].to_json,
        label: "optimal"
      }
      f.puts(training_entry.to_json)
    end
  end
end

