class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :lockable, :omniauthable

  scope :is_database_provider, -> {where('provider is null or provider = ?', 'database')}

  has_many :user_permissions, inverse_of: :user, dependent: :destroy
  has_many :permission_types, through: :user_permissions
  has_many :oauth_applications, through: :permission_types

  has_many :email_bounces, foreign_key: :email, primary_key: :email

  has_many :user_applications, inverse_of: :user, dependent: :destroy

  belongs_to :created_by, class_name: User

  has_many :children, class_name: User, foreign_key: :created_by_id, dependent: :nullify
  has_many :invitations, class_name: UserApplication, foreign_key: :invited_by_id, dependent: :nullify
  has_many :request_assignments, class_name: UserApplication, foreign_key: :assigned_to_id, dependent: :nullify

  has_many :rce_virtual_adfs_users, class_name: 'Contractor::RceVirtualAdfsUser', dependent: :destroy
  has_many :estore_profiles, class_name: 'Contractor::EstoreProfile', foreign_key: :user_guid, primary_key: :guid
  has_many :impersonation_logs, class_name: 'Contractor::ImpersonationLog'
  has_many :devise_log_histories, inverse_of: :user, dependent: :destroy

  attr_accessor :login
  attr_accessor :skip_password_complexity_validation

  before_validation :check_blank_username, :check_blank_provider
  validate :check_password_complexity, unless: :skip_password_complexity_validation
  before_save :check_password_changed
  after_save :complete_invitations, if: Proc.new { |user| user.last_sign_in_at_changed? && user.last_sign_in_at.present? }
  validates_presence_of :email
  validates_presence_of :provider
  validates :username,
            :presence => true,
            :uniqueness => {
                :case_sensitive => false,
                :scope => :provider
            },
            :format => { :with => /\A^[a-zA-Z0-9_@\-\. ]*$\z/, :message => 'must contain letters, numbers, spaces, and @, _, -, or . characters only' }

  after_initialize do
    if new_record?
      self.provider ||= 'database'
    end
  end

  def get_jwt
    dk_token = Doorkeeper::AccessToken.find_or_create_for(OauthApplication.find_by_name('UMS'), self.id, 'public', 2.hours, false)
    jwt = JwtHelper.from_access_token(dk_token)
  end

  def is_database_provider
    self.provider.nil? || self.provider == 'database'
  end

  def set_password_for_external_provider
    if !is_database_provider
      self.password = Devise.friendly_token[0,20]
      self.skip_password_complexity_validation = true
    end
  end

  def check_blank_provider
    if self.provider.blank?
      self.provider = 'database'
    end
  end

  def check_blank_username
    # if blank username, then generate random one
    if self.username.blank? && !self.email.blank?
      self.username = self.email.split("@").first.gsub(/[^a-zA-Z0-9_@\-\.]/, '_')
      while self.class.for_username(username).exists?
        self.username = SecureRandom.hex(5)
      end
    end
  end

  def self.for_username(username)
    where('lower(username) = ?', username.downcase)
  end

  def check_password_changed
    if changed.include? 'encrypted_password'
      self.last_password_change_at = DateTime.now
      self.password_changed = true
    end
  end

  def check_password_complexity
    if password.present? and (not password.match(/^(?=.*[A-Za-z])(?=.*\d)(?=.*[$@!%*#?&.])[A-Za-z\d$@!%*#?&.]{8,}$/))
      errors.add :password, 'must contain at least 1 letter, 1 number, and 1 special character ($, @, !, %, *, #, ., ?, &)'
    end
  end

  def login=(login)
    @login = login
  end

  def login
    @login || self.username || self.email
  end

  def uid
    id.blank? ? nil : (sprintf '%08d', id)
  end

  def application(name)
    user_applications.joins(:oauth_application).where(oauth_applications: { name: name }).first
  end

  def complete_invitations
    user_applications.each do |ua|
      ua.complete
    end
  end

  def self.find_by_invitation_token(token)
    joins(:user_applications).where(user_applications: { invitation_token: token }).first
  end

  def self.for_permission_and_value(application_name, permission_code, value)
    application = OauthApplication.find_by_name(application_name)
    value = value.respond_to?(:map) ? value.map{|v| v.respond_to?(:downcase) ? v.downcase : v} : (value.respond_to?(:downcase) ? value.downcase : value) if value
    joins(:permission_types).joins(:user_permissions).where(permission_types: { oauth_application_id: application.id, code: permission_code}).where("? = ANY(string_to_array(lower(user_permissions.value), ','))", value).uniq
  end

  def self.for_invitation_status(application_name, status)
    application = OauthApplication.find_by_name(application_name)
    active_uas = UserApplication.where(oauth_application_id: application.id).for_invitation_status(status)
    where(id: active_uas.pluck(:user_id))
  end

  rails_admin do
    object_label_method :email

    list do
      include_fields :id,:email,:username,:first_name,:last_name,:sign_in_count,:last_sign_in_at,:failed_attempts,:locked_at,:last_password_change_at,:provider,:admin,:preferred_language,:shared_mailbox,:guid
    end

    show do
      include_fields :id,:email,:username,:first_name,:last_name,:created_by,:created_at,:updated_at
      include_fields :sign_in_count,:last_sign_in_at,:failed_attempts,:locked_at,:last_password_change_at,:provider,:provider_metadata,:admin,:preferred_language,:shared_mailbox,:guid,:user_permissions,:user_applications
      configure :password_changed do
        visible do
          bindings[:object].is_database_provider
        end
      end
      configure :last_password_change_at do
        visible do
          bindings[:object].is_database_provider
        end
        formatted_value do
					unless value.nil?
						distance = distance_of_time_in_words(value, DateTime.now)
						in_future = value > DateTime.now
						"#{value.to_s} - #{in_future ? 'in ' : ''}#{distance}#{in_future ? '' : ' ago'}"
					end
        end
      end
      include_fields :estore_profiles, :rce_virtual_adfs_users, :email_bounces
    end

    create do
      include_fields :provider,:email, :username,:first_name,:last_name,:password,:admin,:preferred_language,:shared_mailbox,:created_by_id
      field :email do
        help 'Required. Must be unique.'
      end
      field :username do
        help 'Required. Must be unique and contain letters, numbers, and _ or . characters only.'
      end
      field :password do
        help 'Required. Must contain at least 1 letter, 1 number, and 1 special character ($, @, !, %, *, #, ., ?, &).'
      end
      field :created_by_id, :hidden do
        visible true
        default_value do
          bindings[:controller].current_user.id
        end
      end
    end

    edit do
      include_fields :email,:username,:first_name,:last_name,:password,:admin,:preferred_language,:shared_mailbox,:provider
      field :uid do
        read_only true
        help ''
      end
      field :email do
        help 'Required. Must be unique.'
      end
      field :username do
        help 'Required. Must be unique and contain letters, numbers, and _ or . characters only.'
      end
      field :password do
        help 'Required. Must contain at least 1 letter, 1 number, and 1 special character ($, @, !, %, *, #, ., ?, &).'
      end
    end

  end

  def provider_enum
    [ ['Database', 'database'] ] + SamlIdentityProvider.all.pluck(:name, :token)
  end

  def preferred_language_enum
    [
      ['English', 'en'],
      ['Spanish', 'es'],
      ['Portuguese', 'pt'],
      ['French', 'fr'],
      ['German', 'de'],
      ['Italian', 'it'],
      ['Dutch', 'nl'],
      ['Russian', 'ru']
    ]
  end

  def name
    "#{first_name} #{last_name}" || email
  end

  #https://github.com/plataformatec/devise/wiki/How-To:-Email-only-sign-up
  # def password_required?
  #   super if confirmed?
  # end

  def password_match?
    self.errors[:password] << "can't be blank" if password.blank?
    self.errors[:password_confirmation] << "can't be blank" if password_confirmation.blank?
    self.errors[:password_confirmation] << "does not match password" if password != password_confirmation
    password == password_confirmation && !password.blank?
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    conditions[:email].downcase! if conditions[:email]
    if login = conditions.delete(:login)
      where(conditions.to_hash).where('provider is null or provider = ?', 'database').where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      where(conditions.to_hash).where('provider is null or provider = ?', 'database').first
    end
  end
  def self.find_for_authentication(warden_conditions)
    conditions = warden_conditions.dup
    conditions[:email].downcase! if conditions[:email]
    if login = conditions.delete(:login)
      where(conditions.to_hash).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      where(conditions.to_hash).first
    end
  end

  def is_customer_portal_user
    user_permissions.to_a.any?{
        |p|
      p.is_customer_portal_permission
    }
  end
  def is_exclusive_customer_portal_user
    user_permissions.present? &&
    user_permissions.to_a.all?{
        |p|
      p.is_customer_portal_permission
    }
  end
  def is_customer_portal_admin
    user_permissions.to_a.any?{
        |p|
      p.is_customer_portal_admin_permission
    }
  end
  def is_okta_user
    provider == 'okta'
  end

  def has_permission?(application_name, permission_code, value = nil)
    PermissionHelper.has_permission?(user_permissions.eager_load(permission_type: :oauth_application).to_a, application_name, permission_code, value)
  end
  def get_permission_value(application_name, permission_code)
    PermissionHelper.get_permission_value(user_permissions.to_a, application_name, permission_code)
  end

  def update_permissions_from_hash(permissions, current_user, current_application)
    # clean out existing permissions for applications calling user has access to
    existing_user_permissions = User.get_current_application_permissions(self.user_permissions, current_user, current_application)

    # TODO - safeguard "permissions" array for current_user/current_application, similar to get_current_application_permissions but on array instead of relation

    permission_ids_updated_or_added = []

    if !permissions.blank?
      permissions.each do |p|
        code = p['permission']
        raise "Each permission must have a 'permission' property associated with it" if code.blank?
        oauth_application = OauthApplication.find_by_name!(p['application'])
        permissionType = PermissionType.find_or_create_by!(code:code,oauth_application_id: oauth_application.id)
        userPermission = UserPermission.find_or_initialize_by(user_id: self.id, permission_type_id: permissionType.id)
        userPermission.value = p['value']
        userPermission.save!
        permission_ids_updated_or_added << userPermission.id
      end

      self.reload
    end

    existing_user_permissions.where.not(id: permission_ids_updated_or_added).destroy_all

    existing_user_permissions = User.get_current_application_permissions(self.user_permissions, current_user, current_application)
    if !existing_user_permissions.any?
      ua = self.application(current_application.name)
      if ua.present?
        ua.deactivate
      end
    end

    self.reload
  end

  def update_from_rce
    # update from RCE
    self.delay.update_from_rce!(true)
  end
  def update_from_rce!(retriable = false)
    # synchronous version of above
    do_this_on_each_retry = Proc.new do |exception, try, elapsed_time, next_interval|
      log_error "#{exception.class}: '#{exception.message.chomp}' - #{try} tries in #{elapsed_time} seconds and #{next_interval} seconds until the next try."
    end
    Retriable.retriable tries: (retriable ? 3 : 1), on: [Timeout::Error, Errno::ECONNRESET], on_retry: do_this_on_each_retry do
      data = RceHelper.provision_user(self)

      data = User.normalize_param_hash(data, nil, OauthApplication.find_by_name('CONTRACTOR_PORTAL'))

      email_updated = false
      name_updated = false
      if self.is_database_provider
        if self.email != data[:email]
          self.update(email: data[:email])
          email_updated = true
        end
        if self.first_name != data[:first_name] || self.last_name != data[:last_name]
          self.update(first_name: data[:first_name], last_name: data[:last_name])
          name_updated = true
        end
      end

      ua = self.application('CONTRACTOR_PORTAL')
      if ua.present?
        ua.update_attributes(application_data: data[:application_data]) unless HashDiff.diff(ua.application_data||{}, data[:application_data]||{}).empty?
      end


      existing_user_permissions = self.user_permissions.joins(permission_type: [:oauth_application]).where(oauth_applications: { name: 'CONTRACTOR_PORTAL'})
      old_permissions_hash = User.get_permissions_hash(existing_user_permissions)
      self.update_permissions_from_hash(data[:permissions], nil, OauthApplication.find_by_name('CONTRACTOR_PORTAL'))
      new_user_permissions = self.user_permissions.joins(permission_type: [:oauth_application]).where(oauth_applications: { name: 'CONTRACTOR_PORTAL'})
      new_permissions_hash = User.get_permissions_hash(new_user_permissions)

      permissions_updated = new_permissions_hash != old_permissions_hash

      if email_updated || name_updated || permissions_updated
        RceHelper.update_mdms_on_user_edit(self)
      end
    end
  end

  def self.get_permissions_hash(user_permissions_relation)
    md5 = Digest::MD5.new
    user_permissions_relation.order(permission_type_id: :asc).each do |p|
      md5.update "#{p.permission_type.oauth_application.name}//#{p.permission_type.code}//#{p.value}"
    end
    md5.hexdigest
  end

  def self.get_current_application_permissions(user_permissions_relation, current_user, current_application)
    perms_for_application = user_permissions_relation.to_a.select{
        |p|
      p.permission_type.oauth_application.name == current_application.name || current_user.has_permission?('UMS', 'CROSS_APPLICATION_PERMISSIONS', p.permission_type.oauth_application.name)
    }
    user_permissions_relation.where(id: perms_for_application.map{|p| p.id})
  end

  def self.normalize_param_hash(hash, current_user, current_application)
    user_params = hash.deep_dup
    user_params = user_params.with_indifferent_access if Hash===hash
    user_params.deep_transform_keys! {|k| k.to_s.underscore.to_sym }

    # normalize alternate field names (contact -> external_id, user_permissions -> permissions, permissions.permission_type_code -> permission, permissions.code -> permission)
    fix_param_name user_params, :contact, :external_id
    fix_param_name user_params, :invited_by_email, :created_by_email
    fix_param_name user_params, :requestor_email, :created_by_email
    fix_param_name user_params, :user_permissions, :permissions
    user_params[:permissions] = user_params[:permissions].map {
        |v|
      fix_param_name v, :permission_type_code, :permission
      fix_param_name v, :code, :permission
      fix_param_name v, :application_code, :application
      v
    } if user_params[:permissions].present?

    # assign current application to any permissions that are blank application
    user_params[:permissions] = user_params[:permissions].map {
        |v|
      v.merge!({application: current_application.name}) if v[:application].blank?
      v
    } if user_params[:permissions].present?

    # filter out permissions user doesn't have access to
    user_params[:permissions] = user_params[:permissions].select {
        |v|
      v[:application].blank? || v[:application] == current_application.name || current_user.has_permission?('UMS', 'CROSS_APPLICATION_PERMISSIONS', v[:application])
    } if user_params[:permissions].present?

    # drop the list of permissions if blank
    user_params.extract!(:permissions) if user_params[:permissions].blank?

    # merge incoming permissions by application+code into CSV
    unless user_params[:permissions].blank?
      output_list = []
      user_params[:permissions].group_by{|val| {application: val[:application], permission: val[:permission]}}.each do |key, val|
        output_list << {
            application: key[:application],
            permission: key[:permission],
            value: val.map{|c| c[:value]}.compact.join(',')
        }.with_indifferent_access
      end

      user_params[:permissions] = output_list
    end

    # exclude a bunch of keys to prevent overposting to user model
    whitelist = %w(external_id email created_by_email first_name last_name username language permissions)
    extra_keys = user_params.keys - whitelist

    # some keys are specific to the model or rails or "application_params" in controller
    model_keys = %w(password password_confirmation) + User.attribute_names
    rails_keys = %w(action controller)
    application_params_keys = %w(postpone_invite assigned_to form_submit_id request_status application)
    application_data_keys = extra_keys - rails_keys - model_keys - application_params_keys

    user_params[:application_data] = user_params.extract!(*application_data_keys) unless application_data_keys.blank?

    user_params.extract!(*extra_keys)

    user_params
  end

  def password_changed_count
    devise_log_histories.where(devise_action: "password_changed").count
  end

  def log_in_count
    devise_log_histories.where(devise_action: "signed_in").count
  end

  private
  def self.fix_param_name(param_collection, from, to)
    new_param = {}
    new_param[to] = param_collection[from]
    param_collection.merge!(new_param).extract!(from) if !param_collection[from].nil? && param_collection[to].nil?
  end
end
