scheduler = Rufus::Scheduler.new

scheduler.every("30m") do
	Station.get_data
end 