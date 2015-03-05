require 'brakeman/checks/base_check'

#Checks for string interpolation and parameters in calls to
#Kernel#system, Kernel#exec, Kernel#syscall, and inside backticks.
#
#Examples of command injection vulnerabilities:
#
# system("rf -rf #{params[:file]}")
# exec(params[:command])
# `unlink #{params[:something}`
class Brakeman::CheckExecute < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Finds instances of possible command injection"

  SAFE_VALUES = [s(:const, :RAILS_ROOT),
                  s(:call, s(:const, :Rails), :root),
                  s(:call, s(:const, :Rails), :env)]

  #Check models, controllers, and views for command injection.
  def run_check
    Brakeman.debug "Finding system calls using ``"
    check_for_backticks tracker

    Brakeman.debug "Finding other system calls"
    calls = tracker.find_call :targets => [:IO, :Open3, :Kernel, :'POSIX::Spawn', :Process, nil],
      :methods => [:capture2, :capture2e, :capture3, :exec, :pipeline, :pipeline_r,
        :pipeline_rw, :pipeline_start, :pipeline_w, :popen, :popen2, :popen2e, 
        :popen3, :spawn, :syscall, :system]

    Brakeman.debug "Processing system calls"
    calls.each do |result|
      process_result result
    end
  end

  #Processes results from Tracker#find_call.
  def process_result result
    call = result[:call]
    args = call.arglist
    first_arg = call.first_arg

    case call.method
    when :system, :exec
      failure = include_user_input?(first_arg) || dangerous_interp?(first_arg)
    else
      failure = include_user_input?(args) || dangerous_interp?(args)
    end

    if failure and not duplicate? result
      add_result result

      if failure.type == :interp #Not from user input
        confidence = CONFIDENCE[:med]
      else
        confidence = CONFIDENCE[:high]
      end

      warn :result => result,
        :warning_type => "Command Injection", 
        :warning_code => :command_injection,
        :message => "Possible command injection",
        :code => call,
        :user_input => failure.match,
        :confidence => confidence
    end
  end

  #Looks for calls using backticks such as
  #
  # `rm -rf #{params[:file]}`
  def check_for_backticks tracker
    tracker.find_call(:target => nil, :method => :`).each do |result|
      process_backticks result
    end
  end

  #Processes backticks.
  def process_backticks result
    return if duplicate? result

    add_result result

    exp = result[:call]

    if input = include_user_input?(exp)
      confidence = CONFIDENCE[:high]
      user_input = input.match
    elsif input = dangerous?(exp)
      confidence = CONFIDENCE[:med]
      user_input = input
    else
      return
    end

    warn :result => result,
      :warning_type => "Command Injection",
      :warning_code => :command_injection,
      :message => "Possible command injection",
      :code => exp,
      :user_input => user_input,
      :confidence => confidence
  end

  def dangerous? exp
    exp.each_sexp do |e|
      next if node_type? e, :lit, :str
      next if SAFE_VALUES.include? e

      if call? e and e.method == :to_s
        e = e.target
      end

      if node_type? e, :or, :evstr, :string_eval, :string_interp
        if res = dangerous?(e)
          return res
        end
      else
        return e
      end
    end

    false
  end

  def dangerous_interp? exp
    match = include_interp? exp
    return unless match
    interp = match.match

    interp.each_sexp do |e|
      if res = dangerous?(e)
        return Match.new(:interp, res)
      end
    end

    false
  end
end
