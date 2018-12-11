json.type 'application'
json.id application.uid
json.name application.name

json.permissions application.application_permissions do |p|
  json.partial! '/api/v1/permissions/permission', permission: p
end
