class ApiPolicy
  attr_reader :user, :scope

  def initialize(user, scope)
    @user = user
    @scope = scope
  end

  def has_permission(code,record=nil)
    if @user.nil?
      false
    else
      if @user.respond_to?(:has_permission?)
        @user.has_permission?('UMS', code, record.try(:id))
      else
        PermissionHelper.has_permission?(@user.permissions.to_a, 'UMS', code, record.try(:id))
      end
    end
  end

  def has_resource_permission(permission,record=nil)
    has_permission("#{@scope.model_name.human.pluralize}_#{permission}",record)
  end

  def index?
    has_resource_permission("manage") || has_resource_permission("view")
  end

  def show?
    has_resource_permission("manage",@scope) || has_resource_permission("view",@scope)
  end

  def authenticate?
    has_resource_permission("authenticate",@scope)
  end

  def create?
    has_resource_permission("manage",@scope)
  end

  def new?
    create?
  end

  def update?
    has_resource_permission("manage",@scope)
  end

  def edit?
    update?
  end

  def destroy?
    has_resource_permission("manage",@scope)
  end

  def scope
    Pundit.policy_scope!(user_context, record.class)
  end

  class Scope
    attr_reader :user_context, :scope, :parent

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope
    end
  end
end
