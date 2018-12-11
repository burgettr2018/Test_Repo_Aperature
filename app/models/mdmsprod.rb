class MDMSPROD
  include HTTParty
  base_uri ENV["MDMS_PROD_URL"]
  #debug_output $stdout

  def self.datamart_payer(account_number)
    secure_request("/api/v1/datamart/payer?account_number=#{account_number}")[:data]
  end

  def self.datamart_soldto(account_number)
    secure_request("/api/v1/datamart/soldto?account_number=#{account_number}")[:data]
  end

  def self.datamart_shipto(account_number)
    secure_request("/api/v1/datamart/shipto?account_number=#{account_number}")[:data]
  end

  def self.payers_for_shipto(account_number)
    secure_request("/api/v1/datamart/payers_for_shipto?account_number=#{account_number}")[:data]
  end

  def self.payers_for_soldto(account_number)
    secure_request("/api/v1/datamart/payers_for_soldto?account_number=#{account_number}")[:data]
  end


  private

  def self.dateize_string_fields(object)
    object.inject({}){
        |result, (key,value)|
      value = Date.parse(value) if key =~ /_date$/
      result[key] = value
      result
    }
  end

  def self.request(url,query = nil,headers = nil,options = {})
    begin
      Rails.logger.debug "#{url}, #{query}, #{headers}"
      if options[:method] == :post
        response = post(url, query:query, :headers => headers)
      else
        response = get(url, query:query, :headers => headers)
      end
      if response.success?
        {
            data:options[:skip_parse] ? response : JSON.parse(response.body, {:quirks_mode => true}),
            headers:response.headers
        }
      elsif response.code == 404 || response.code == 401
        {
            data: ''
        }
      else
        raise  "#{response.message} #{response.body}"
      end
    rescue => e
      Rails.logger.error { "Error request: #{e.message} #{e.backtrace.join("\n")}" }
      raise e
    end
  end

  def self.secure_request(url,query = nil)
    request(url,query,{"Authorization" => "Bearer #{fetch_token}"})
  end

  def self.logged_in_user_request(user_token,url,query = nil,options = {})
    request(url,query,{"Authorization" => "Bearer #{user_token}"},options)
  end

  def self.authentication_headers
    { "Authorization" => "Bearer #{get_application_token}" }
  end

  def self.fetch_token
    #Rails.cache.fetch("oauth_token", expires_in: 5.minutes) do
    client = OAuth2::Client.new(ENV['MDMS_PROD_CLIENT_ID'],ENV['MDMS_PROD_SECRET'],{site: "https://login.owenscorning.com/oauth/token"})
    client.client_credentials.get_token.token
    #end
  end

end
