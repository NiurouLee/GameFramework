---@class UnityEngine.ParticleSystem : UnityEngine.Component
---@field isPlaying bool
---@field isEmitting bool
---@field isStopped bool
---@field isPaused bool
---@field particleCount int
---@field time float
---@field randomSeed uint
---@field useAutoRandomSeed bool
---@field proceduralSimulationSupported bool
---@field main UnityEngine.ParticleSystem.MainModule
---@field emission UnityEngine.ParticleSystem.EmissionModule
---@field shape UnityEngine.ParticleSystem.ShapeModule
---@field velocityOverLifetime UnityEngine.ParticleSystem.VelocityOverLifetimeModule
---@field limitVelocityOverLifetime UnityEngine.ParticleSystem.LimitVelocityOverLifetimeModule
---@field inheritVelocity UnityEngine.ParticleSystem.InheritVelocityModule
---@field forceOverLifetime UnityEngine.ParticleSystem.ForceOverLifetimeModule
---@field colorOverLifetime UnityEngine.ParticleSystem.ColorOverLifetimeModule
---@field colorBySpeed UnityEngine.ParticleSystem.ColorBySpeedModule
---@field sizeOverLifetime UnityEngine.ParticleSystem.SizeOverLifetimeModule
---@field sizeBySpeed UnityEngine.ParticleSystem.SizeBySpeedModule
---@field rotationOverLifetime UnityEngine.ParticleSystem.RotationOverLifetimeModule
---@field rotationBySpeed UnityEngine.ParticleSystem.RotationBySpeedModule
---@field externalForces UnityEngine.ParticleSystem.ExternalForcesModule
---@field noise UnityEngine.ParticleSystem.NoiseModule
---@field collision UnityEngine.ParticleSystem.CollisionModule
---@field trigger UnityEngine.ParticleSystem.TriggerModule
---@field subEmitters UnityEngine.ParticleSystem.SubEmittersModule
---@field textureSheetAnimation UnityEngine.ParticleSystem.TextureSheetAnimationModule
---@field lights UnityEngine.ParticleSystem.LightsModule
---@field trails UnityEngine.ParticleSystem.TrailModule
---@field customData UnityEngine.ParticleSystem.CustomDataModule
local m = {}
---@param customData table
---@param streamIndex UnityEngine.ParticleSystemCustomData
function m:SetCustomParticleData(customData, streamIndex) end
---@param customData table
---@param streamIndex UnityEngine.ParticleSystemCustomData
---@return int
function m:GetCustomParticleData(customData, streamIndex) end
---@overload fun(subEmitterIndex:int, particle:UnityEngine.ParticleSystem.Particle):void
---@overload fun(subEmitterIndex:int, particles:table):void
---@param subEmitterIndex int
function m:TriggerSubEmitter(subEmitterIndex) end
---@overload fun(particles:table, size:int):void
---@overload fun(particles:table):void
---@overload fun(particles:Unity.Collections.NativeArray, size:int, offset:int):void
---@overload fun(particles:Unity.Collections.NativeArray, size:int):void
---@overload fun(particles:Unity.Collections.NativeArray):void
---@param particles table
---@param size int
---@param offset int
function m:SetParticles(particles, size, offset) end
---@overload fun(particles:table, size:int):int
---@overload fun(particles:table):int
---@overload fun(particles:Unity.Collections.NativeArray, size:int, offset:int):int
---@overload fun(particles:Unity.Collections.NativeArray, size:int):int
---@overload fun(particles:Unity.Collections.NativeArray):int
---@param particles table
---@param size int
---@param offset int
---@return int
function m:GetParticles(particles, size, offset) end
---@overload fun(t:float, withChildren:bool, restart:bool):void
---@overload fun(t:float, withChildren:bool):void
---@overload fun(t:float):void
---@param t float
---@param withChildren bool
---@param restart bool
---@param fixedTimeStep bool
function m:Simulate(t, withChildren, restart, fixedTimeStep) end
---@overload fun():void
---@param withChildren bool
function m:Play(withChildren) end
---@overload fun():void
---@param withChildren bool
function m:Pause(withChildren) end
---@overload fun(withChildren:bool):void
---@overload fun():void
---@param withChildren bool
---@param stopBehavior UnityEngine.ParticleSystemStopBehavior
function m:Stop(withChildren, stopBehavior) end
---@overload fun():void
---@param withChildren bool
function m:Clear(withChildren) end
---@overload fun():bool
---@param withChildren bool
---@return bool
function m:IsAlive(withChildren) end
---@overload fun(emitParams:UnityEngine.ParticleSystem.EmitParams, count:int):void
---@param count int
function m:Emit(count) end
function m.ResetPreMappedBufferMemory() end
UnityEngine = {}
UnityEngine.ParticleSystem = m
return m