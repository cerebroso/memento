class Tapedeck
  include Singleton
  
  class ErrorOnRewind < StandardError;end
  
  def recording(user)
    start(user)
    yield
    @session
  ensure
    stop
  end
  
  def start(user_or_id)
    user = User.find_by_id(user_or_id)
    @session = user ? Tapedeck::Session.new(:user => user) : nil
  end
  
  def stop
    @session = nil
  end
  
  def add_track(action_type, recorded_object)
    return unless save_session
    @session.add_track(action_type, recorded_object)
  end
  
  def recording?
    !!(defined?(@session) && @session)
  end
  
  private
  
  def save_session
    recording? && (!@session.changed? || @session.save)
  end
end

require 'tapedeck/result'
require 'tapedeck/action'
require 'tapedeck/record_changes'
require 'tapedeck/record_in_controller'
require 'tapedeck/track'
require 'tapedeck/session'