local lu = require('luaunit')

TestController = {}

function TestController:when_wrappers_are_called_should_delegate_and_return_true()
    local controller = Controller

    lu.assertTrue(SetControllerTask(controller, { id = "Mission", params = {} }))
    lu.assertTrue(ResetControllerTask(controller))
    lu.assertTrue(PushControllerTask(controller, { id = "Mission", params = {} }))
    lu.assertTrue(PopControllerTask(controller))
    lu.assertEquals(HasControllerTask(controller), true)
    lu.assertTrue(SetControllerCommand(controller, { id = "Script", params = {} }))
    lu.assertTrue(SetControllerOnOff(controller, true))
    lu.assertTrue(SetControllerAltitude(controller, 1000))
    lu.assertTrue(SetControllerSpeed(controller, 200))
    lu.assertTrue(SetControllerOption(controller, 0, 1))
    lu.assertEquals(type(GetControllerDetectedTargets(controller)), "table")
    lu.assertTrue(KnowControllerTarget(controller, {}))
    lu.assertTrue(IsControllerTargetDetected(controller, {}))
end

function TestController:when_creating_tasks_should_match_expected_shape()
    local orbit = CreateOrbitTask("Circle", { x = 1, y = 2, z = 3 }, 1000, 200)
    lu.assertNotNil(orbit)
    lu.assertNotNil(orbit.params)
    lu.assertNotNil(orbit.params.point)
    lu.assertEquals(orbit.id, "orbit")
    lu.assertEquals(orbit.params.point.x, 1)

    local follow = CreateFollowTask(1, { x = 0, y = 0, z = 0 }, 5)
    lu.assertNotNil(follow)
    lu.assertNotNil(follow.params)
    lu.assertEquals(follow.id, "follow")
    lu.assertEquals(follow.params.groupId, 1)

    local escort = CreateEscortTask(2, nil, 3, 40000)
    lu.assertNotNil(escort)
    lu.assertNotNil(escort.params)
    lu.assertEquals(escort.id, "escort")
    lu.assertEquals(escort.params.engagementDistMax, 40000)

    local atkGroup = CreateAttackGroupTask(10, nil, true, 100, 1, 90)
    lu.assertNotNil(atkGroup)
    lu.assertNotNil(atkGroup.params)
    lu.assertEquals(atkGroup.params.groupAttack, true)

    local atkUnit = CreateAttackUnitTask(99)
    lu.assertNotNil(atkUnit)
    lu.assertNotNil(atkUnit.params)
    lu.assertEquals(atkUnit.params.unitId, 99)

    local bomb = CreateBombingTask({ x = 1, y = 0, z = 2 })
    lu.assertNotNil(bomb)
    lu.assertEquals(bomb.id, "Bombing")

    local runway = CreateBombingRunwayTask(1)
    lu.assertNotNil(runway)
    lu.assertEquals(runway.id, "BombingRunway")

    local land = CreateLandTask({ x = 0, y = 0, z = 0 }, true, 30)
    lu.assertNotNil(land)
    lu.assertEquals(land.id, "land")

    local refuel = CreateRefuelingTask()
    lu.assertNotNil(refuel)
    lu.assertEquals(refuel.id, "refueling")

    local fac = CreateFACAttackGroupTask(5)
    lu.assertNotNil(fac)
    lu.assertEquals(fac.id, "FAC_AttackGroup")

    local fire = CreateFireAtPointTask({ x = 0, y = 0, z = 0 }, 100)
    lu.assertNotNil(fire)
    lu.assertEquals(fire.id, "fireAtPoint")

    local hold = CreateHoldTask()
    lu.assertNotNil(hold)
    lu.assertEquals(hold.id, "hold")

    local goTo = CreateGoToWaypointTask(1, 2)
    lu.assertNotNil(goTo)
    lu.assertEquals(goTo.id, "goToWaypoint")

    local wrapped = CreateWrappedAction({ id = "Script", params = {} }, true)
    lu.assertNotNil(wrapped)
    lu.assertEquals(wrapped.id, "WrappedAction")
end

function TestController:when_creating_options_should_have_correct_ids()
    lu.assertEquals(CreateROEOption(0).id, 0)
    lu.assertEquals(CreateReactionOnThreatOption(1).id, 1)
    lu.assertEquals(CreateRadarUsingOption(1).id, 3)
    lu.assertEquals(CreateFlareUsingOption(1).id, 4)
    lu.assertEquals(CreateFormationOption(1).id, 5)
    lu.assertEquals(CreateRTBOnBingoOption(true).id, 6)
    lu.assertEquals(CreateSilenceOption(true).id, 7)
    lu.assertEquals(CreateAlarmStateOption(2).id, 9)
    lu.assertEquals(CreateRTBOnOutOfAmmoOption(true).id, 10)
    lu.assertEquals(CreateECMUsingOption(1).id, 13)
    lu.assertEquals(CreateProhibitAAOption(true).id, 14)
    lu.assertEquals(CreateProhibitJettisonOption(true).id, 15)
    lu.assertEquals(CreateProhibitABOption(true).id, 16)
    lu.assertEquals(CreateProhibitAGOption(true).id, 17)
    lu.assertEquals(CreateMissileAttackOption(1).id, 18)
    lu.assertEquals(CreateProhibitWPPassReportOption(true).id, 19)
    -- Removed CreateDispersalOnAttackOption

    -- Removed CreateProhibitWPPassReport2Option
end

function TestController:when_setting_common_options_should_call_setOption()
    local controller = Controller
    -- smoke test for convenience setters
    lu.assertTrue(ControllerSetProhibitAA(controller, true))
    lu.assertTrue(ControllerSetProhibitAG(controller, false))
    lu.assertTrue(ControllerSetProhibitAB(controller, true))
    lu.assertTrue(ControllerSetProhibitJettison(controller, true))
    lu.assertTrue(ControllerSetROE(controller, 0))
    lu.assertTrue(ControllerSetReactionOnThreat(controller, 1))
    lu.assertTrue(ControllerSetRadarUsing(controller, 1))
    lu.assertTrue(ControllerSetFlareUsing(controller, 1))
    lu.assertTrue(ControllerSetFormation(controller, 1))
    lu.assertTrue(ControllerSetRTBOnBingo(controller, true))
    lu.assertTrue(ControllerSetSilence(controller, true))
    lu.assertTrue(ControllerSetAlarmState(controller, 2))
    lu.assertTrue(ControllerSetRTBOnOutOfAmmo(controller, true))
    lu.assertTrue(ControllerSetECMUsing(controller, 1))
    lu.assertTrue(ControllerSetProhibitWPPassReport(controller, true))
    lu.assertTrue(ControllerSetMissileAttack(controller, 1))
    lu.assertTrue(ControllerSetMissileAttack(controller, "NEZ_RANGE"))
    -- ground-specific option via a ground controller (reuse Controller mock)
    lu.assertTrue(ControllerSetDisperseOnAttack(controller, 120))
    -- Removed unsupported options: ProhibitWPPassReport2, DispersalOnAttack
end

return TestController


