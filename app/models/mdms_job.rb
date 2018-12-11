class MdmsJob < Delayed::Job
	establish_connection :mdms
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
	def args
		begin
			dj_method = YAML.parse(handler).children.first.children.to_a
			args = dj_method[5]
			arg_string = ""
			if args && args.children
				arg_string << '<ul>'
				args.children.each do |c|
					arg_string << '<li>'
					if Psych::Nodes::Mapping === c
						if c.children.try(:first).try(:value) == 'raw_attributes'
							arg_string << name_from_tag(c)
							c = c.children[1]
						end
						stream = Psych::Nodes::Stream.new
						doc    = Psych::Nodes::Document.new
						stream.children << doc
						doc.children    << c
						arg_string << stream.to_yaml.sub(/^---/, '').gsub(/\n/, "\n  ").sub(/\n  $/, "\n").gsub(' ', '&nbsp;')
					elsif Psych::Nodes::Scalar === c
						arg_string << c.value << "\n"
					else
						arg_string << c.to_s << "\n"
					end
					arg_string << '</li>'
				end
				arg_string << '</ul>'
			end
			arg_string
		rescue
			''
		end
	end
	rails_admin do
		label 'MDMS Job'
		navigation_label 'Jobs'
		list do
			include_fields :id, :attempts, :queue
			field :method
			include_fields :last_error, :run_at, :failed_at
		end
		show do
			include_fields :id, :attempts, :queue
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
