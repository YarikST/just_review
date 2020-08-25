class UserHazard < ApplicationRecord

  belongs_to :user
  belongs_to :hazard
  has_many :achievements, as: :entity

  after_commit  :run_notify, on: [ :create, :update ]

  after_save    :create_achievement_like
  after_save    :create_achievement_awareness
  after_save    :follow_create,  if: :follow?
  after_save    :follow_destroy, if: :unfollow?
  after_destroy :follow_destroy, if: :unfollow_destroy?

  validate      :rock_awareness, on: :update

  class << self
    def viewers_query(params)
      roles = Role.arel_table
      users = User.arel_table
      hazards = Hazard.arel_table
      user_hazards = UserHazard.arel_table

      q = users
              .join(user_hazards, Arel::Nodes::InnerJoin).on(
                  user_hazards[:user_id].eq(users[:id]).and(user_hazards[:see].eq(true))
              )
              .join(hazards, Arel::Nodes::InnerJoin).on(
                  hazards[:id].eq(user_hazards[:hazard_id]).and(hazards[:id].eq(params[:hazard_id]))
              )
              .join(roles, Arel::Nodes::InnerJoin).on(roles[:id].eq(users[:role_id]))

      fields = []
      if params[:count]
        fields << users[:id].count
      else
        fields << users[Arel.star]
        fields << roles[:name].as('role_name')
        fields << user_hazards[:like]
      end

      q.where(
          Arel::Nodes::SqlLiteral.new("users.first_name || ' ' || users.last_name")
              .matches("%#{params[:name]}%")) if params[:name].present?
      q.where(user_hazards[:like].eq(params[:like])) if [true, 'true'].include? params[:like]

      q.project(*fields)

      q
    end

  end

  private

  def rock_awareness
    if awareness_changed? && awareness_was
      self.errors.add :awareness, 'You dont change the attribute'
    end
  end

  def _new_record?
    saved_change_to_id?
  end

  def follow?
    saved_change_to_like? && like
  end

  def unfollow?
    saved_change_to_like? && !like && !_new_record?
  end

  def follow_create
    user_follow_hazard = user.user_follow_hazards.find_or_initialize_by({user_id: user_id, hazard_id: hazard_id})

    unless user_follow_hazard.save
      errors.add :hazard, "You can not follow a user on this hazard"
      raise ActiveRecord::RecordInvalid
      # raise ActiveRecord::Rollback
    end
  end

  def unfollow_destroy?
    like
  end

  def follow_destroy
    user_follow_hazard = user.user_follow_hazards.find_by({user_id: user_id, hazard_id: hazard_id})

    unless user_follow_hazard&.destroy
      errors.add :hazard, "You can not unfollow a user on this hazard"
      raise ActiveRecord::RecordInvalid
      # raise ActiveRecord::Rollback
    end
  end

  def run_notify
    if saved_change_to_like? && like
      unless hazard.created_user.id == user_id || hazard.created_user.employee? == false
        NotificationBroadcastJob.perform_async  :hazard_rated, {user_id: user_id, hazard_id: hazard_id}
      end
      NotificationBroadcastJob.perform_async  :hazard_rated_in_area, {user_id: user_id, hazard_id: hazard_id}
    end
  end

  def create_achievement_like
    if like_changed_to?(true) && achievements.where(achievement_type: AchievementType.hazard_like).empty?
      Achievement.create_if_active(achievement_type: AchievementType.hazard_like, user_id: user_id, entity: self)
    end
  end

  def create_achievement_awareness
    if saved_change_to_awareness? && awareness && achievements.where(achievement_type: AchievementType.hazard_awareness).empty?
      Achievement.create_if_active(achievement_type: AchievementType.hazard_awareness, user_id: user_id, entity: self)
    end
  end

  def like_changed_to?(new_value)
    saved_change_to_like? && self.like == new_value
  end

end
