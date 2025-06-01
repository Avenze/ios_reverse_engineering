
GameTimer = {
	stack = {},
	_id = 0
}

------------------------------ public methods ------------------------------

--interval is in seconds
function GameTimer:CreateNewTimer(interval, func, isLoop, execImmediately)
	return self:CreateNewMilliSecTimer(interval * 1000, func, isLoop, execImmediately)
end

function GameTimer:CreateNewMilliSecTimer(intervalInMilliSec, func, isLoop, execImmediately)
	local timerId = self:_GetNewTimerId()
	local isLoop = isLoop and true or false
	local currentLocalTime = self:_GetCurrentTime()
	local endTime = currentLocalTime + intervalInMilliSec
	local newTimer = {
		_interval = intervalInMilliSec,
		_deadLine = endTime,
		_callback = func,
		_id = timerId,
		_isLoop = isLoop
	}
	table.insert(self.stack, newTimer)

	if execImmediately then
		func()
	end
	return timerId
end

function GameTimer:StopTimer(timerId)
    local gameTimerStack = self.stack
    local stackSize = #gameTimerStack
	for i = stackSize, 1, -1 do
		if gameTimerStack[i]._id == timerId then
            gameTimerStack[i]._isInvalid = true
            return
		end
	end
end

------------------------------ public methods end ------------------------------

function GameTimer:Update(dt)
	self.deltaTime = dt
	local currentLocalTime = self:_GetCurrentTime()
    local gameTimerStack = self.stack
	local stackSize = #gameTimerStack
	for i = stackSize, 1, -1 do
		local currentTimer = gameTimerStack[i]
		if currentTimer then
			if currentTimer._isInvalid then
				table.remove(gameTimerStack, i)
			else
				if currentTimer._deadLine <= currentLocalTime then
					if currentTimer._callback then
						currentTimer._callback()
					end

					if currentTimer._isLoop then
						self:_RenewTimer(currentTimer,currentLocalTime)
					else
						table.remove(gameTimerStack, i)
					end
				end
			end
		end
	end
end

function GameTimer:RemoveAllTimer()
	self.stack = {}
end

function GameTimer:TimerIsInvalidByID(id)
	if not id then
		return true
	end

	local stackSize = #self.stack
	for i = stackSize, 1, -1 do
		if self.stack[i]._id == id then
			return false
		end
	end
	return true
end

------------------------------ private methods ------------------------------
function GameTimer:_GetCurrentTime()
	if GameTimeManager.GetCurrentServerTimeInMilliSec then
		return GameTimeManager:GetCurrentServerTimeInMilliSec()
	else
		return GameTimeManager:GetCurrentServerTime() * 1000
	end
end

function GameTimer:_RemoveTimer(timeID)
	local stackSize = Tools:GetTableSize(GameTimer.stack)
	for i = stackSize, 1, -1 do
		if GameTimer.stack[i]._id == timeID then
			table.remove(GameTimer.stack, i)
		end
	end
end

function GameTimer:_RenewTimer(timer,now)
	local currentLocalTime = now or self:_GetCurrentTime()
	timer._deadLine = currentLocalTime + timer._interval
end

function GameTimer:_GetNewTimerId()
	self._id = self._id + 1
	return self._id
end
------------------------------ private methods end ------------------------------
