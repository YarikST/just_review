class Achievement < ApplicationRecord

  belongs_to :achievement_type
  belongs_to :user
  belongs_to :entity, polymorphic: true, optional: true

  before_create :add_points_to_achievement
  after_create :add_points_to_user

  class << self
    def create_if_active(**args)
      if args[:achievement_type].active
        Achievement.create!(**args)
      end
    end

    def search_query(params)
      achievements = Achievement.arel_table
      achievement_types = AchievementType.arel_table

      q = achievements
              .join(achievement_types, Arel::Nodes::OuterJoin).on(achievement_types[:id].eq(achievements[:achievement_type_id]))

      q.where(achievements[:user_id].eq(params[:user_id] || params[:current_user].id))

      fields = []
      if params[:count]
        fields << achievements[:id].count
      else
        q.group(achievements[:achievement_type_id], achievement_types[:id])

        fields << achievement_types[Arel.star]
        fields << achievements[:points].sum.as('points')
      end
      q.project(*fields)

      q.where(achievements[:created_at].between(DateTime.parse(params[:start_date]).in_time_zone .. DateTime.parse(params[:end_date]).in_time_zone)) if params[:start_date].present? && params[:end_date].present?

      q
    end
  end

  private

  def add_points_to_achievement
    self.points = self.achievement_type.points
  end
  def add_points_to_user
    self.user.increment!(:points, self.achievement_type.points)
  end
end
