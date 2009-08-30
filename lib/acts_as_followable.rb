require File.dirname(__FILE__) + '/follower_lib'

module ActiveRecord #:nodoc:
  module Acts #:nodoc:
    module Followable
      
      def self.included(base)
        base.extend ClassMethods
        base.class_eval do
          include FollowerLib
        end
      end
      
      module ClassMethods
        def acts_as_followable
          has_many :follows, :as => :followable, :dependent => :destroy
          include ActiveRecord::Acts::Followable::InstanceMethods
        end
      end

      
      module InstanceMethods
        
        # Returns the number of followers a record has.
        def followers_count
          self.follows.size
        end
        
        #returns the number of blocked followers
        def blocked_followers_count
          self.blocked_followers.size
        end
        
        # Returns the following records.
        def followers
          Follow.find(:all, :include => [:follower], :conditions => ["followable_id = ? AND followable_type = ? AND blocked_at IS NULL", 
              self.id, parent_class_name(self)]).collect {|f| f.follower }
        end
        
        # returns all blocked following objects
        def blocked_followers
          Follow.find(:all, :include => [:follower], :conditions => ["followable_id = ? AND followable_type = ? AND blocked_at IS NOT NULL", 
              self.id, parent_class_name(self)]).collect {|f| f.follower }
        end
        
        #blocks a follower without deleting the record
        def block_follower(follower)
          follower = get_follower(follower)
          if follower
            follower.blocked_at = Date.today
            follower.save
          end
        end
        
        #unblocks a follower
        def unblock_follower(follower)
          follower = get_follower(follower)
          if follower
            follower.blocked_at = nil
            follower.save
          end
        end
        
        # Returns true if the current instance is followed by the passed record.
        def followed_by?(follower)
          Follow.find(:first, :conditions => ["followable_id = ? AND followable_type = ? AND follower_id = ? AND follower_type = ?", self.id, parent_class_name(self), follower.id, parent_class_name(follower)]) ? true : false
        end
        
        private
        
        #returns a follower object
        def get_follower(follower)
          Follow.find(:first, :conditions => ["followable_id = ? AND followable_type = ? AND follower_id = ? AND follower_type = ?", self.id, parent_class_name(self), follower.id, parent_class_name(follower)])
        end
        
      end
      
    end
  end
end
