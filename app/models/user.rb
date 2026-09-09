class User < ApplicationRecord
  ROLES = %w[admin editor sales].freeze # admin: everything; editor: content; sales: leads only

  has_secure_password
  has_many :leads, foreign_key: :assigned_to_id, dependent: :nullify, inverse_of: :assigned_to

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: ROLES }
  validate :email_unique_ci
  normalizes :email, with: ->(e) { e.strip.downcase }

  scope :active, -> { where(active: true) }

  def admin?  = role == "admin"
  def editor? = role.in?(%w[admin editor])
  def sales?  = role.in?(%w[admin sales])

  private

  def email_unique_ci
    errors.add(:email, "مستخدم بالفعل") if User.where.not(id: id).where("lower(email) = ?", email.to_s.downcase).exists?
  end
end
