//===========================================================================
// Rheiko Presents
// Damage Tracker v1.2
//===========================================================================
//
// Requirements:
//  - Unit Indexer by Bribe
//  - Damage Engine v3.8 by Bribe
//
// Damage Tracker allows you to easily retrieve a total amount of damage that
// a unit has dealt by using Damage Engine to detect when a unit takes damage 
// then store the damage information into a hashtable. When the unit taking 
// damage dies, the system clean up the information.
//
// Features:
// - Allows you to retrieve Total Overall/Spell/Physical Damage dealt by a unit
// - Allows you to retrieve Total Overall/Spell/Physical Damage taken by a unit
// - Allows you to retrieve Damage Contribution (in percentage %) by a unit
// - Allows you to retrieve Total Damage dealt by a player
//
// In order to keep memory usage minimum and used only as necessary, the system
// requires you to register the units whose damage you wish to track first. To 
// do so, simply set DTR_IsRegistered[(Custom value of (Your unit))] = True
//
// Damage Tracker has custom events that can help you retrieve damage info,
// they are:
// - DTR_TrackerEvent Equal to 1.00
// - DTR_TrackerEvent Equal to 2.00
//
// You can treat DTR_TrackerEvent Equal to 1.00 just like DamageEvent Equal to 1.00
// (because it actually is based on that) from here, you can retrieve damage dealt
// and damage taken by the actors corresponding to these events, they are DTR_Source
// and DTR_Target.
//
// You can treat DTR_TrackerEvent Equal to 2.00 just like Unit - A unit dies event.
// However, in this event and in this event only, you can also retrieve Damage 
// Contribution by a unit.
//
// Finally, you have a variable called DTR_TotalPlayerDamage[PlayerId] which
// contain the total damage done by each player. This variable is an array 
// and the index is based on PlayerId. Be noted that the index starts from 0.
// 
// Make sure to check the examples to further explore the capability of this system.
// If you have any feedbacks or suggestions, feel free to let me know at
// https://www.hiveworkshop.com/members/rheiko.232216/
//
//===========================================================================

function DTR_ValidateUnit takes unit Source, unit Target returns boolean
    local integer Mode = udg_DTR_RegistrationMode
    local integer SourceId = GetUnitUserData(Source)
    local integer TargetId = GetUnitUserData(Target)

    return (Mode == 1 and not udg_DTR_IsRegistered[SourceId]) or (Mode == 2 and not udg_DTR_IsRegistered[TargetId]) or (Mode == 3 and (not udg_DTR_IsRegistered[SourceId] or not udg_DTR_IsRegistered[TargetId]))
endfunction

function DTR_OnUnitDeath takes nothing returns boolean
    local unit Source = GetKillingUnit()
    local unit Target = GetTriggerUnit()
    local integer SourceKey = GetHandleId(Source)
    local integer TargetKey = GetHandleId(Target)  

    if DTR_ValidateUnit(Source, Target) == true  then
        set Source = null
        set Target = null
        return false
    endif
    
    // Load all the total damage taken
    set udg_DTR_TotalDamageTaken = LoadReal(udg_DTR_Table, 0, TargetKey)
    set udg_DTR_TotalSpellDamageTaken = LoadReal(udg_DTR_Table, 1, TargetKey)
    set udg_DTR_TotalPhysDamageTaken = LoadReal(udg_DTR_Table, 2, TargetKey)

    // Load all the total damage dealt
    set udg_DTR_TotalUnitDamage = LoadReal(udg_DTR_Table, TargetKey, SourceKey)
    set udg_DTR_TotalSpellDamage = LoadReal(udg_DTR_Table, TargetKey + 100000, SourceKey)
    set udg_DTR_TotalPhysicalDamage = LoadReal(udg_DTR_Table, TargetKey + 200000, SourceKey)

    set udg_DTR_OverallDamagePercentage = 0.0
    set udg_DTR_SpellDamagePercentage = 0.0
    set udg_DTR_PhysDamagePercentage = 0.0

    // Ensure total damage taken is not 0
    if udg_DTR_TotalDamageTaken > 0.0 then
        set udg_DTR_OverallDamagePercentage = (udg_DTR_TotalUnitDamage / udg_DTR_TotalDamageTaken) * 100
    endif

    if udg_DTR_TotalSpellDamageTaken > 0.0 then
        set udg_DTR_SpellDamagePercentage = (udg_DTR_TotalSpellDamage / udg_DTR_TotalSpellDamageTaken) * 100
    endif

    if udg_DTR_TotalPhysDamageTaken > 0.0 then
        set udg_DTR_PhysDamagePercentage = (udg_DTR_TotalPhysicalDamage / udg_DTR_TotalPhysDamageTaken) * 100
    endif

    set udg_DTR_Source = Source
    set udg_DTR_Target = Target

    set udg_DTR_TrackEvent = 0.0 
    set udg_DTR_TrackEvent = 2.0
    set udg_DTR_TrackEvent = 0.0 

    set udg_DTR_Source = null
    set udg_DTR_Target = null
    
    call RemoveSavedReal(udg_DTR_Table, 0, TargetKey)
    call RemoveSavedReal(udg_DTR_Table, 1, TargetKey)
    call RemoveSavedReal(udg_DTR_Table, 2, TargetKey)
    call RemoveSavedReal(udg_DTR_Table, 3, TargetKey)
    call FlushChildHashtable(udg_DTR_Table, TargetKey)
    call FlushChildHashtable(udg_DTR_Table, TargetKey + 100000)
    call FlushChildHashtable(udg_DTR_Table, TargetKey + 200000)

    set Source = null
    set Target = null
    
    return false
endfunction

function DTR_BeforeUnitDamage takes nothing returns boolean
    local unit Source = udg_DamageEventSource
    local unit Target = udg_DamageEventTarget
    local integer TargetKey = GetHandleId(Target)
    local real TargetHP = GetUnitState(Target, UNIT_STATE_LIFE)

    if DTR_ValidateUnit(Source, Target) == true then
        set Source = null
        set Target = null
        return false
    endif

    call SaveReal(udg_DTR_Table, 3, TargetKey, TargetHP)

    set Source = null
    set Target = null
    return false
endfunction

function DTR_OnUnitDamage takes nothing returns boolean
    local unit Source = udg_DamageEventSource
    local unit Target = udg_DamageEventTarget
    local integer SourceKey = GetHandleId(Source)
    local integer TargetKey = GetHandleId(Target)
    local integer PlayerId = GetPlayerId(GetOwningPlayer(Source))
    local real TempDmg = udg_DamageEventAmount
    local real TargetHP = 0.0

    if DTR_ValidateUnit(Source, Target) == true then
        set Source = null
        set Target = null
        return false
    endif

    // Load data
    
    set TargetHP = LoadReal(udg_DTR_Table, 3, TargetKey)

    if TargetHP <= TempDmg then
        set TempDmg = TargetHP
    endif
    
    set udg_DTR_TotalDamageTaken = LoadReal(udg_DTR_Table, 0, TargetKey)   
    set udg_DTR_TotalSpellDamageTaken = LoadReal(udg_DTR_Table, 1, TargetKey) 
    set udg_DTR_TotalPhysDamageTaken = LoadReal(udg_DTR_Table, 2, TargetKey)
 
    set udg_DTR_TotalUnitDamage = LoadReal(udg_DTR_Table, TargetKey, SourceKey) 
    set udg_DTR_TotalSpellDamage = LoadReal(udg_DTR_Table, TargetKey + 100000, SourceKey) 
    set udg_DTR_TotalPhysicalDamage = LoadReal(udg_DTR_Table, TargetKey + 200000, SourceKey)

    set udg_DTR_TotalPlayerDamage[PlayerId] = udg_DTR_TotalPlayerDamage[PlayerId] + TempDmg

    // Update Data

    set udg_DTR_TotalDamageTaken = udg_DTR_TotalDamageTaken + TempDmg
    call SaveReal(udg_DTR_Table, 0, TargetKey, udg_DTR_TotalDamageTaken)

    set udg_DTR_TotalUnitDamage = udg_DTR_TotalUnitDamage + TempDmg
    call SaveReal(udg_DTR_Table, TargetKey, SourceKey, udg_DTR_TotalUnitDamage)

    if udg_IsDamageSpell == true then        
        set udg_DTR_TotalSpellDamageTaken = udg_DTR_TotalSpellDamageTaken + TempDmg
        call SaveReal(udg_DTR_Table, 1, TargetKey, udg_DTR_TotalSpellDamageTaken)
 
        set udg_DTR_TotalSpellDamage = udg_DTR_TotalSpellDamage + TempDmg
        call SaveReal(udg_DTR_Table, TargetKey + 100000, SourceKey, udg_DTR_TotalSpellDamage)

        set udg_DTR_TotalPlayerSpellDamage[PlayerId] = udg_DTR_TotalPlayerSpellDamage[PlayerId] + TempDmg

    else
        set udg_DTR_TotalPhysDamageTaken = udg_DTR_TotalPhysDamageTaken + TempDmg
        call SaveReal(udg_DTR_Table, 2, TargetKey, udg_DTR_TotalPhysDamageTaken)

        set udg_DTR_TotalPhysicalDamage = udg_DTR_TotalPhysicalDamage + TempDmg
        call SaveReal(udg_DTR_Table, TargetKey + 200000, SourceKey, udg_DTR_TotalPhysicalDamage)

        set udg_DTR_TotalPlayerPhysDamage[PlayerId] = udg_DTR_TotalPlayerPhysDamage[PlayerId] + TempDmg

    endif        

    set udg_DTR_Source = Source
    set udg_DTR_Target = Target

    set udg_DTR_TrackEvent = 0.0
    set udg_DTR_TrackEvent = 1.0
    set udg_DTR_TrackEvent = 0.0 

    set udg_DTR_Source = null
    set udg_DTR_Target = null

    set Source = null
    set Target = null
    return false
endfunction

//===========================================================================
function InitTrig_Damage_Tracker takes nothing returns nothing
    local integer i = bj_MAX_PLAYERS
    local trigger mainTrg = CreateTrigger()
    local trigger secondTrg = CreateTrigger()
    local trigger deathTrg = CreateTrigger()
    call TriggerRegisterVariableEvent(mainTrg, "udg_DamageEvent", EQUAL, 1.00)
    call TriggerRegisterVariableEvent(secondTrg, "udg_DamageModifierEvent", EQUAL, 1.00)
    loop
        set i = i - 1
        call TriggerRegisterPlayerUnitEvent(deathTrg, Player(i), EVENT_PLAYER_UNIT_DEATH, null)
        exitwhen i == 0
    endloop
    call TriggerAddCondition( mainTrg, Condition( function DTR_OnUnitDamage ))
    call TriggerAddCondition( secondTrg, Condition( function DTR_BeforeUnitDamage ))
    call TriggerAddCondition( deathTrg, Condition( function DTR_OnUnitDeath ))

    set udg_DTR_Table = InitHashtable()

    set mainTrg = null
    set secondTrg = null
    set deathTrg = null
endfunction

