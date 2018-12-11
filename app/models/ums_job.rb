class UmsJob < Delayed::Job
	def method
		begin
			dj_method = YAML.parse(handler).children.first.children.to_a
			name = name_from_tag(dj_method[1])
			method_name = dj_method[3].value.sub(/^:/,'')

			"#{name}##{method_name}"
		rescue
			''
		end
	end
	def raw_args
		begin
			dj_method = YAML.parse(handler).children.first.children.to_a
			args = dj_method[5]
			response = []
			if args && args.children
				args.children.each do |c|
					if Psych::Nodes::Mapping === c
						if c.children.try(:first).try(:value) == 'raw_attributes'
							response << name_from_tag(c)
							c = c.children[1]
						end
						stream = Psych::Nodes::Stream.new
						doc    = Psych::Nodes::Document.new
						stream.children << doc
						doc.children    << c
						response << stream.to_yaml.sub(/^---/, '').gsub(/\n/, "\n  ").sub(/\n  $/, "\n").gsub(' ', '&nbsp;')
					elsif Psych::Nodes::Scalar === c
						response << c.value
					else
						response << c.to_s
					end
				end
			end
			response
		rescue
			nil
		end
	end
	def args
		arg_string = ''
		raw = raw_args
		if raw.present?
			arg_string << '<ul>'
			raw.each do |c|
				arg_string << '<li>'
				arg_string << c.to_s << "\n"
				arg_string << '</li>'
			end
			arg_string << '</ul>'
		end
		arg_string
	end
	rails_admin do
		label 'UMS Job'
		navigation_label 'Jobs'
		list do
			include_fields :id, :attempts
			field :method
			include_fields :last_error, :run_at, :failed_at
		end
		show do
			include_fields :id, :attempts
			field :method
			field :args, :text do
				formatted_value do
					value.to_s.gsub(/\n/, '<br>').html_safe
				end
			end
			configure :handler, :text do
				formatted_value do
					value.to_s.gsub(/\n/, '<br>').gsub(' ', '&nbsp;').html_safe
				end
			end
			configure :last_error, :text do
				formatted_value do
					value.to_s.gsub(/\n/, '<br>').html_safe
				end
			end
			include_fields :last_error, :run_at, :locked_at, :locked_by, :failed_at, :queue, :priority, :handler, :created_at, :updated_at
		end
	end
	private
	def name_from_tag(item)
		tag = item.tag
		if tag == '!ruby/class'
			name = item.value
		else
			name = tag.sub(/^![^:]*:/,'')
		end
	end
end
