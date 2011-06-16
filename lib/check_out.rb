require 'active_support/concern'

module CheckOut
  extend ActiveSupport::Concern

  class AlreadyCheckedOutError < Exception; end

  class NotYoursError < Exception; end

  included do
    belongs_to :checked_out_by_user, polymorphic: true
  
    scope :checked_out_to, lambda { |u=nil|
      u ?
        where(
          checked_out_by_user_id: u.id,
          checked_out_by_user_type: u.class.name
        ) :
        checked_out
    }
  
    scope :checked_out,
          where("#{table_name}.checked_out_by_user_id IS NOT NULL OR #{table_name}.checked_out_by_user_type IS NOT NULL OR #{table_name}.checked_out_at IS NOT NULL")
        
    scope :released,
          where("#{table_name}.checked_out_by_user_id IS NULL AND #{table_name}.checked_out_by_user_type IS NULL AND #{table_name}.checked_out_at IS NULL")
  
    scope :released_or_checked_out_by, lambda { |u|
      where("#{table_name}.checked_out_by_user_id IS NULL OR (#{table_name}.checked_out_by_user_id = ? AND #{table_name}.checked_out_by_user_type = ?)", u.id, u.class.name)
    }
  
    scope :available_to, lambda { |u| released_or_checked_out_by(u) }
  end


  module ClassMethods
    def check_out_all(user)
      ids = select("#{table_name}.id").map(&:id)
    
      unscoped do
        where(id: ids).
        update_all(
          checked_out_by_user_id: user.id,
          checked_out_by_user_type: user.class.name,
          checked_out_at: Time.zone.now
        )
      end unless ids.empty?
    end
    alias :check_out_all_to :check_out_all
  
    def release_all_checkouts(user=nil)
      if user
        ids = select("#{table_name}.id").where(
          checked_out_by_user_id: user.id,
          checked_out_by_user_type: user.class.name
        ).map(&:id)
      else
        ids = select("#{table_name}.id").checked_out.map(&:id)
      end
    
      unscoped do
        changes = {
          checked_out_by_user_id: nil,
          checked_out_by_user_type: nil,
          checked_out_at: nil
        }
      
        where(id: ids).update_all(changes)
      end unless ids.empty?
    end
    alias :release_all_checkouts_from :release_all_checkouts
  end
  
  
  def checked_out_to?(user)
    checked_out? &&
    checked_out_by_user_type == user.class.name &&
    checked_out_by_user_id == user.id
  end
  
  def checked_out?
    checked_out_at?
  end

  def checkout(check_out_to_user)
    changes = {}
  
    if checked_out? && checked_out_by_user_id != check_out_to_user.id
      raise AlreadyCheckedOutError, "#{self.class} #{self.id} is already checked out by #{checked_out_by_user_type} #{checked_out_by_user_id}"
    elsif checked_out? && checked_out_by_user_id == check_out_to_user.id
      changes[:checked_out_at] = 
        write_attribute(:checked_out_at, current_time_from_proper_timezone)
    else
      changes[:checked_out_by_user_id] =
        write_attribute(:checked_out_by_user_id, check_out_to_user.id)
      changes[:checked_out_by_user_type] =
        write_attribute(:checked_out_by_user_type, check_out_to_user.class.name)
      changes[:checked_out_at] =
        write_attribute(:checked_out_at, current_time_from_proper_timezone)
    end
  
    self.class.unscoped do
      self.class.update_all changes, { id: self.id }
    end
  end
  alias :check_out   :checkout
  alias :checkout_to :checkout

  def release(releasing_user=nil)
    if releasing_user && releasing_user.id == checked_out_by_user_id
      release
    elsif releasing_user
      raise NotYoursError, "#{self.class} #{self.id} is not checked out by #{releasing_user.class.name} #{releasing_user.id} and cannot be released"
    end
  
    changes = {}
    changes[:checked_out_by_user_id] =
      write_attribute(:checked_out_by_user_id, nil)
    changes[:checked_out_by_user_type] =
      write_attribute(:checked_out_by_user_type, nil)
    changes[:checked_out_at] = write_attribute(:checked_out_at, nil)
  
    self.checked_out_by_user = nil
  
    self.class.unscoped do
      self.class.update_all changes, { id: self.id }
    end
  end
  alias :release_from :release

  def update_attributes_and_release(params={})
    params = params.merge(
      checked_out_by_user_id: nil,
      checked_out_at: nil,
      checked_out_by_user_type: nil
    )
    
    update_attributes params
  end
end
