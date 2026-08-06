--!strict

-- TimeService: clock game (server-authoritative), day/season/weather.
-- Skeleton: satu tick per detik, siarkan ke client via RemoteEvent.

local timeInfo = {
	dayNumber = 1,
	hour = 6, -- mulai jam 6 pagi
	minute = 0,
	season = 'summer',
	weather = 'clear',
}

local TimeService = {}

function TimeService.init()
	-- Tick tiap detik; 1 detik = 1 menit game (durasi 1 hari = 20 menit real)
	task.spawn(function()
		while true do
			task.wait(1)
			timeInfo.minute += 1
			if timeInfo.minute >= 60 then
				timeInfo.minute = 0
				timeInfo.hour += 1
				if timeInfo.hour >= 24 then
					timeInfo.hour = 0
					timeInfo.dayNumber += 1
				end
			end
		end
	end)
end

function TimeService.getTimeInfo(): typeof(timeInfo)
	return timeInfo
end

return TimeService
