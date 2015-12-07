# Where all the changes to tracked models are kept
class HistoryTracker
  include Mongoid::History::Tracker

  # The tag is non-cloud.net users such as admins, bots, workers, etc
  field :modifier_tag

  # The included :scope field (as defiend by Mongoid::History::Tracker) references the class of the tracked object.
  # So we add a :scope_id to easily find all archives of a particular object.
  field :scope_id

  # Also make a note of any objects that are owned by a user
  field :scope_owned_by_id

  before_save do
    self.scope_id = trackable.id.to_s
    self.scope_owned_by_id = trackable.user.try(:id) if trackable.respond_to? :user
    self.modifier_tag = Cloudnet.current_user

    # Only set the modifier relationsip if the modifier is an actual cloud.net user. All other potential modifiers
    # are stored as a simple modifer_tag
    self.modifier = Cloudnet.current_user if Cloudnet.current_user.is_a? User
  end

  class << self
    # Find all archives concerning a given user
    def concerning_user(user_id)
      self.or(
        # If the user modified the object
        modifier_id: user_id
      ).or(
        # If the user was the actual object modified
        scope: 'user', scope_id: user_id
      ).or(
        # If the modified object is owned by the concerned user
        scope_owned_by_id: user_id
      )
    end
  end

  # All purpose method to return the modifier, whether that's a user, admin or bot.
  # We can't use modifier() because that's already taken by HistoryTracker.
  def modified_by
    return modifier if modifier.is_a? User
    if modifier_tag.to_s.start_with? 'admin'
      id = modifier_tag.split('-')[1]
      AdminUser.find(id)
    else
      modifier_tag
    end
  end
end
