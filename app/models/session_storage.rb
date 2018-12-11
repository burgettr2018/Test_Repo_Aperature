class SessionStorage < ActiveRecord::Base

  def self.get(session_id,key)
    SessionStorage.where(session_id:session_id,name:key).first.try(:value)
  end

  def self.set(session_id,key,value)
    ss = SessionStorage.find_or_create_by(session_id:session_id,name:key)
    ss.value = value
    ss.save!
  end

  def self.delete(session_id,key)
    SessionStorage.where(session_id:session_id,name:key).delete_all
  end

end
