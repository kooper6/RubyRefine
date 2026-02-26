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
    code = actions[:alpha]['code'] || ""
    
    unless valid_syntax?(code)
      return { reward: -10, style_score: 0, review_quality: 0, judge_feedback: "CRITICAL: Syntax Error. Code will not execute."}

    style_score = perform_static_analysis(code)

    review_quality = @judge.evaluate_review_depth(actions[:alpha], actions[:beta])

    final_reward = (style_score * 4) + (review_quality * 6) #rubocop 40, logic 60

    {
      reward: final_reward.round(2),
      style_score: style_score,
      review_quality: review_quality['score'],
      judge_feedback: review_quality['feedback']
    }
  end

  private

  def valid_syntax?(code)
    return false if code.empty?

    Tempfile.create(['syntax_check', '.rb']) do |f|
      f.write(code)
      f.flush
      system("ruby -c #{f.path} > /dev/null 2>&1")
    end
  end

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
