# careful, check UserPermissionSerializer code before making changes, need to be in sync until we can move away from this entirely
json.application permission.permission_type.oauth_application.try(:name)||'NONE'
json.permission permission.permission_type.code
json.value permission.value
