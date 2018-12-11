# Feature flag list and enabled status

# enable here in code file when we turn on the live env, this way as devs run they are in sync with what is turned on
# this also gives us a good list to search for flagging code to remove

begin
	# old flags no longer in codebase
	%i(
	).each do |f|
		Feature.flipper[f].remove
	end

	# enabled flags
	%i(
	).each do |f|
		Feature.flipper[f].enable
	end
rescue => e
	puts e
end

# we should consider a way to clean up other old or weird feature flags here
# maybe a third "in-progress" list would work and anything not in the 3 lists is wiped
