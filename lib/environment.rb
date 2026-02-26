require_relative 'judge'
require 'tempfile'

class Environment
  attr_reader: state

  def initialize
    @judge = Judge.new(endpoint: "127.0.0.1:11433")

    @state = { 
      current_task: "General Code Review",
      context_files: [],
      standards: "Solid, DRY, Perfromance"
    }
  end

  def step(actions)
    code = actions[:alpha]['code']

    style_score = perform_static_analysis(code)

    rewiew_quality = @judge.evaluate_review_depth(actions[:alpha], actions[:beta])

    final_reward = (style_score * 4) + (rewiew_quality * 6) #rubocop 40, logic 60

    {
      reward: final_reward.round(2),
      style_score: style_score,
      rewiew_quality: rewiew_quality['score'],
      judge_feedback: rewiew_quality['feedback']
    }
  end

  private

  def perform_static_analysis(code)
    return 0.0 if code.empty?
    score = 0.0
    Tempfile.create(['dev', '.rb']) do |f|
      f.write(code)
      f.flush
      output = `rubocop #{f.path} --format json --lint`
      data = JSON.parse(output)
      offenses = data.dig('files', 0, 'offenses')&.size || 0 
      score = [1.0 - (offenses * 0.1), 0.0].max
    end
    score
  rescue
    0.0
  end
end
