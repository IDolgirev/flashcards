require "super_memo"

class Card < ActiveRecord::Base
  include Swagger::Blocks
  swagger_schema :Card do
    key :id, :Card
    key :required, [
                     :id,
                     :original_text,
                     :translated_text,
                     :review_date,
                     :block_id
                   ]
    property :id do
      key :type, :integer
      key :format, :int64
    end
    property :original_text do
      key :type, :string
    end
    property :translated_text do
      key :type, :string
    end
    property :block_id do
      key :type, :integer
    end
    property :review_date do
      key :type, :string
      key :format, "date-time"
    end
  end

  swagger_schema :CardResponse do
    key :id, :Card
    property :card do
      key :'$ref', :Card
    end
  end

  swagger_schema :CardsResponse do
    key :id, :Card
    property :cards do
      key :type, :array
      items do
        key :'$ref', :Card
      end
    end
  end

  swagger_schema :CardReviewResult do
    property :result do
      key :type, :string
    end
  end

  swagger_schema :CardReview do
    key :id, :Card
    key :required, [:id, :original_text]
    property :id do
      key :type, :integer
      key :format, :int64
    end
    property :original_text do
      key :type, :string
    end
  end

  swagger_schema :CardReviewResponse do
    key :id, :Card
    property :card do
      key :'$ref', :CardReview
    end
  end

  belongs_to :user
  belongs_to :block
  before_validation :set_review_date_as_now, on: :create
  validates :user_id,
            :interval,
            :repeat,
            :efactor,
            :quality,
            :attempt,
            presence: true
  validates :original_text,
            :translated_text,
            :review_date,
            presence: { message: "Необходимо заполнить поле." }
  validates :user_id, presence: { message: "Ошибка ассоциации." }
  validates :block_id,
            presence: { message: "Выберите колоду из выпадающего списка." }
  validate :texts_are_not_equal
  mount_uploader :image, CardImageUploader

  scope :pending, -> { where("review_date <= ?", Time.now).order("RANDOM()") }
  scope :repeating, -> { where("quality < ?", 4).order("RANDOM()") }

  def check_translation(user_translation)
    distance = Levenshtein.distance(full_downcase(translated_text),
                                    full_downcase(user_translation))
    sm_hash = SuperMemo.algorithm(
      interval, repeat, efactor, attempt, distance, 1)
    if distance <= 1
      successful_review_update(sm_hash, distance)
    else
      unsuccessful_review_update(sm_hash, distance)
    end
  end

  def self.pending_cards_notification
    users = User.where.not(email: nil)
    users.each do |user|
      if user.cards.pending.any?
        CardsMailer.pending_cards_notification(user.email).deliver
      end
    end
  end

  protected

  def successful_review_update(sm_hash, distance)
    sm_hash.merge!(review_date: Time.now + interval.to_i.days, attempt: 1)
    update(sm_hash)
    { state: true, distance: distance }
  end

  def unsuccessful_review_update(sm_hash, distance)
    sm_hash.merge!(attempt: [attempt + 1, 5].min)
    update(sm_hash)
    { state: false, distance: distance }
  end

  def set_review_date_as_now
    self.review_date = Time.now
  end

  def texts_are_not_equal
    if full_downcase(original_text) == full_downcase(translated_text)
      errors.add(:original_text, "Вводимые значения должны отличаться.")
    end
  end

  def full_downcase(str)
    str.mb_chars.downcase.to_s.squeeze(" ").lstrip
  end
end
