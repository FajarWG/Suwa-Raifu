--!strict

-- TestRunner: menjalankan TestEZ di server saat sesi test (rojo test).
-- Memuat semua file test (*.spec.lua) di Shared.

local ReplicatedFirst = game:GetService("ReplicatedFirst")

local TestEZ = require(ReplicatedFirst:WaitForChild("TestEZ"))

local srcRoot = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local testModules = ReplicatedFirst:WaitForChild("TestModules")

local results = TestEZ.TestBootstrap:run({ srcRoot, testModules }, TestEZ.Reporters.TextReporter)
TestEZ.Reporters.TextReporter:finish()

if results.failureCount > 0 then
	error(`[TestEZ] {results.failureCount} test(s) failed`, 0)
end
