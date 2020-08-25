class Department < ApplicationRecord

  belongs_to :company
  belongs_to :supervisor, class_name: 'User', optional: true
  has_many :areas, dependent: :destroy
  has_many :company_users, through: :company, source: :users
  has_many :area_users, through: :areas, source: :users
  has_many :active_area_users, through: :areas, source: :active_users

  validates :name,
            presence: true,
            length: {maximum: 500}

  validate  :validate_destroy

  validates :location,
            presence: {message: 'Location can\'t be blank.'}


  validates :address,
            presence: {message: 'Address can\'t be blank.'},
            length: {maximum: 100, message: "Address must be in range"},
            format: {with: ValidationHelper::UNICODE_TEXT, message: "Incorrect format of the address"}

  validate :location_floor_uniqueness, if: ->{ location.present? }

  after_commit  :run_notify_create, on: :create

  before_destroy :run_notify_destroy

  class << self

    def search_query(params)
      departments = Department.arel_table

      q = departments.project(params[:count] ? "COUNT(*)" : Arel.star)

      q.where(departments[:company_id].eq(params[:company_id]))


      if params[:count]
      else
        q.group(departments[:id])

        if Department.column_names.include?(params[:sort_column]) && %w(asc desc).include?(params[:sort_type])
          q.order(departments[params[:sort_column]].send(params[:sort_type] == 'asc' ? :asc : :desc))
        else
          q.order(departments[:id].desc)
        end
      end

      q.where(departments[:name].matches("%#{params[:name]}%")) if params[:name].present?


      q
    end

    def search_area_query(params)
      departments = Department.arel_table
      areas = Area.arel_table

      q = departments
              .join(areas, Arel::Nodes::InnerJoin).on(areas[:department_id].eq(departments[:id]))

      q.where(departments[:company_id].eq(params[:company_id]))
      q.where(departments[:id].eq(params[:department_id]))

      q.where(areas[:id].not_eq(params[:skip_area_id])) if params[:skip_area_id].present?

      fields = []
      if params[:count] == true
        fields << departments[:id].count
      else
        q.group(departments[:id], areas[:id])

        fields<< areas[Arel.star]
      end
      q.project(*fields)

      q
    end

    def search_intersects_query(params)
      departments                 = Department.arel_table

      q = departments.project(departments[Arel.star])

      q.where(departments[:id].not_eq(params[:id])) if params[:id].present?
      q.where(departments[:company_id].eq(params[:company_id]))
      q.where(Arel::Nodes::InfixOperation.new('&&', departments[:location], Arel::Nodes::SqlLiteral.new("'#{params[:location]}'")))

      q
    end

    def search_area_which_intersect_department_query(params)
      areas                 = Area.arel_table

      q = areas.project(areas[Arel.star].count)

      q.where(areas[:department_id].eq(params[:id]))
      q.where(Arel::Nodes::InfixOperation.new('<@', areas[:location], Arel::Nodes::SqlLiteral.new("'#{params[:location]}'")))

      q
    end

  end

  def poligon
    reg =  /\((?:([-+]?[0-9]+(?:\.[0-9]+)*)\,([-+]?[0-9]+(?:\.[0-9]+)*))+\)/;

    location.scan(reg).map{|mas| {latitude:mas[0].to_f, longitude:mas[1].to_f }}
  end


  private

  def location_floor_uniqueness
    intersect_departments = Department.find_by_sql Department.search_intersects_query({id: id, company_id: company_id, location: location})
    intersect_areas = Department.find_by_sql Department.search_area_which_intersect_department_query({id: id, location: location})

    if intersect_departments.first.present?
      # errors.add :location, "location duplicate (#{intersect_areas.reduce(' ') do|memo, area| memo += area.title + ' ' end})"
      errors.add :location, 'Department with similar coordinates is already in use'
    end

    if intersect_areas.first.count != areas.count
      errors.add :location, 'Department coordinates should include all area'
    end
  end

  def run_notify_create
    NotificationBroadcastJob.perform_async  :department_new, {department_id: id}
  end

  def run_notify_destroy
    NotificationBroadcastJob.new.perform  :department_delete, {"department_id" => id}
  end

  def validate_destroy
    if marked_for_destruction? && areas.count > 0
      errors.add(:base,
                 {
                     code: '',
                     message: "Can not be deleted while there is a area"
                 }
      )
      throw :abort
    end
  end

end
