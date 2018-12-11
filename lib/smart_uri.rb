#https://gist.github.com/zernel/0f10c71f5a9e044653c1a65c6c5ad697

require 'uri'

module SmartURI
	SEPARATOR = '/'

	def self.join(*paths, query: nil)
		paths = paths.compact.reject(&:empty?)
		last = paths.length - 1
		url = paths.each_with_index.map { |path, index|
			_expand(path, index, last)
		}.join
		if query.nil?
			return url
		elsif query.is_a? Hash
			return url + "?#{URI.encode_www_form(query.to_a)}"
		else
			raise "Unexpected input type for query: #{query}, it should be a hash."
		end
	end

	def self._expand(path, current, last)
		if path.starts_with?(SEPARATOR) && current != 0
			path = path[1..-1]
		end

		unless path.ends_with?(SEPARATOR) || current == last
			path = [path, SEPARATOR]
		end

		path
	end
end