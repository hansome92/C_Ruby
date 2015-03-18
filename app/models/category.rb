class Category < ActiveRecord::Base
  has_many :projects
  validates_presence_of :name_de
  validates_uniqueness_of :name_de

  def self.with_projects
    where("exists(select true from projects p where p.category_id = categories.id and p.state not in('draft', 'rejected'))")
  end

  def self.array
    [['Select an option', '']].concat order('name_'+ I18n.locale.to_s + ' ASC').collect { |c| [c.send('name_' + I18n.locale.to_s), c.id] }
  end

  def name_pt
    name_de
  end

  def to_s
    self.send('name_' + I18n.locale.to_s)
  end
end
