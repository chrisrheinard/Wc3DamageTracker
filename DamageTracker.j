//===========================================================================
// Rheiko Presents
// Damage Tracker v1.2.3
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


//=========== API ============

function GetDamageTrackerData takes nothing returns boolean
    local integer SourceKey
    local integer TargetKey    

    if udg_DTR_SourceParam != null and udg_DTR_TargetParam != null then
        set SourceKey = GetHandleId(udg_DTR_SourceParam)
        set TargetKey = GetHandleId(udg_DTR_TargetParam)

        // Load all the total damage taken
        set udg_DTR_TotalDamageTaken = LoadReal(udg_DTR_Table, 0, TargetKey)
        set udg_DTR_TotalSpellDamageTaken = LoadReal(udg_DTR_Table, 1, TargetKey)
        set udg_DTR_TotalPhysDamageTaken = LoadReal(udg_DTR_Table, 2, TargetKey)

        // Load all the total damage dealt
        set udg_DTR_TotalUnitDamage = LoadReal(udg_DTR_Table, TargetKey, SourceKey)
        set udg_DTR_TotalSpellDamage = LoadReal(udg_DTR_Table, TargetKey + 100000, SourceKey)
        set udg_DTR_TotalPhysicalDamage = LoadReal(udg_DTR_Table, TargetKey + 200000, SourceKey)
     
        return true
    endif

    return false
endfunction


//===========================================================================

function IsUnitAlive takes unit u returns boolean    
    return (GetWidgetLife(u) > 0.405) 
endfunction

function DTR_ValidateUnit takes unit Source, unit Target returns boolean
    local integer Mode = udg_DTR_RegistrationMode
    local integer SourceId = GetUnitUserData(Source)
    local integer TargetId = GetUnitUserData(Target)

    return (Mode == 1 and not udg_DTR_IsRegistered[SourceId]) or (Mode == 2 and not udg_DTR_IsRegistered[TargetId]) or (Mode == 3 and (not udg_DTR_IsRegistered[SourceId] or not udg_DTR_IsRegistered[TargetId]))
endfunction

function DTR_ClearTableData takes integer TargetKey returns nothing
    call RemoveSavedReal(udg_DTR_Table, 0, TargetKey)
    call RemoveSavedReal(udg_DTR_Table, 1, TargetKey)
    call RemoveSavedReal(udg_DTR_Table, 2, TargetKey)
    call RemoveSavedReal(udg_DTR_Table, 3, TargetKey)
    call RemoveSavedReal(udg_DTR_Table, 4, TargetKey)

    call FlushChildHashtable(udg_DTR_Table, TargetKey)
    call FlushChildHashtable(udg_DTR_Table, TargetKey + 100000)
    call FlushChildHashtable(udg_DTR_Table, TargetKey + 200000)

endfunction

function DTR_LoadTableData takes integer SourceKey, integer TargetKey returns nothing
    // Load all the total damage taken
    set udg_DTR_TotalDamageTaken = LoadReal(udg_DTR_Table, 0, TargetKey)
    set udg_DTR_TotalSpellDamageTaken = LoadReal(udg_DTR_Table, 1, TargetKey)
    set udg_DTR_TotalPhysDamageTaken = LoadReal(udg_DTR_Table, 2, TargetKey)

    // Load all the total damage dealt
    set udg_DTR_TotalUnitDamage = LoadReal(udg_DTR_Table, TargetKey, SourceKey)
    set udg_DTR_TotalSpellDamage = LoadReal(udg_DTR_Table, TargetKey + 100000, SourceKey)
    set udg_DTR_TotalPhysicalDamage = LoadReal(udg_DTR_Table, TargetKey + 200000, SourceKey)
endfunction

function DTR_UpdateTopContributor takes unit source, real damage, integer damageType returns nothing
    if damageType == 1 then
        if damage > udg_DTR_TopContribution then
            set udg_DTR_TopContribution = damage
            set udg_DTR_TopContributor = source
        endif
    endif

    if damageType == 2 then
        if damage > udg_DTR_TopSpellContribution then
            set udg_DTR_TopSpellContribution = damage
            set udg_DTR_TopSpellContributor = source
        endif
    endif

    if damageType == 3 then
        if damage > udg_DTR_TopPhysContribution then
            set udg_DTR_TopPhysContribution = damage
            set udg_DTR_TopPhysContributor = source
        endif
    endif
    
endfunction

function DTR_TimerCallback takes nothing returns nothing
    // Assign locals
    local integer i = 0
    local integer SourceKey
    local integer TargetKey
    local integer TargetId

    // Loop through active pairs
    loop
        set i = i + 1
        exitwhen i > udg_DTR_ActivePairs

        set SourceKey = GetHandleId(udg_DTR_SourceArr[i])
        set TargetKey = GetHandleId(udg_DTR_TargetArr[i])

        // Increase counter if its not expired yet
        if udg_DTR_TimeCounter[i] < udg_DTR_CleanupTime and IsUnitAlive(udg_DTR_TargetArr[i]) then

            set udg_DTR_TimeCounter[i] = LoadReal(udg_DTR_Table, 4, TargetKey)
            set udg_DTR_TimeCounter[i] = udg_DTR_TimeCounter[i] + 1
            call SaveReal(udg_DTR_Table, 4, TargetKey, udg_DTR_TimeCounter[i])

        else
        
            // Clear data
            if IsUnitAlive(udg_DTR_TargetArr[i]) then     
                set TargetId = GetUnitUserData(udg_DTR_TargetArr[i])
                call DTR_ClearTableData(TargetKey)
                call GroupRemoveUnit(udg_DTR_TargetPairGroup[TargetId], udg_DTR_SourceArr[i])
            endif
            
            // Deindex
            set udg_DTR_SourceArr[i] = udg_DTR_SourceArr[udg_DTR_ActivePairs]
            set udg_DTR_SourceArr[udg_DTR_ActivePairs] = null
            set udg_DTR_TargetArr[i] = udg_DTR_TargetArr[udg_DTR_ActivePairs]
            set udg_DTR_TargetArr[udg_DTR_ActivePairs] = null
            set udg_DTR_TimeCounter[i] = udg_DTR_TimeCounter[udg_DTR_ActivePairs]

            set i = i - 1
            set udg_DTR_ActivePairs = udg_DTR_ActivePairs - 1

            if udg_DTR_ActivePairs == 0 then
                call PauseTimer(udg_DTR_Timer)
            endif
        endif
    endloop
endfunction

function DTR_OnUnitDeath takes nothing returns boolean
    // Assign locals
    local unit Killer = GetKillingUnit()
    local unit Target = GetTriggerUnit()
    local integer KillerKey = GetHandleId(Killer)
    local integer TargetKey = GetHandleId(Target)  
    local integer TargetId = GetUnitUserData(Target)
    local integer SourceKey
    local integer SourceId
    local group g
    local unit u
    
    // Validate whether source and/or target registered
    if DTR_ValidateUnit(Killer, Target)  then
        set Killer = null
        set Target = null
        return false
    endif
    
    // Loop through the group owned by the target which contains sources
    set g = udg_DTR_TargetPairGroup[TargetId]
    set u = FirstOfGroup(g)
    loop            
        set SourceKey = GetHandleId(u)
        set SourceId = GetUnitUserData(u)
        
        // Load data of each source
        call DTR_LoadTableData(SourceKey, TargetKey)

        set udg_DTR_OverallContribution[SourceId] = 0.0
        set udg_DTR_SpellContribution[SourceId] = 0.0
        set udg_DTR_PhysContribution[SourceId] = 0.0

        // Ensure total damage taken is not 0
        if udg_DTR_TotalDamageTaken > 0.0 then
            set udg_DTR_OverallContribution[SourceId] = (udg_DTR_TotalUnitDamage / udg_DTR_TotalDamageTaken) * 100
        endif

        if udg_DTR_TotalSpellDamageTaken > 0.0 then
            set udg_DTR_SpellContribution[SourceId] = (udg_DTR_TotalSpellDamage / udg_DTR_TotalSpellDamageTaken) * 100
        endif

        if udg_DTR_TotalPhysDamageTaken > 0.0 then
            set udg_DTR_PhysContribution[SourceId] = (udg_DTR_TotalPhysicalDamage / udg_DTR_TotalPhysDamageTaken) * 100
        endif

        // Calculate top contributors
        call DTR_UpdateTopContributor(u, udg_DTR_OverallContribution[SourceId], 1)
        call DTR_UpdateTopContributor(u, udg_DTR_SpellContribution[SourceId], 2)
        call DTR_UpdateTopContributor(u, udg_DTR_PhysContribution[SourceId], 3)
        
        // Add them to a temp group for accessibility
        call GroupAddUnit(udg_DTR_Sources, u)
        
        call GroupRemoveUnit(g, u)        
        set u = FirstOfGroup(g)
        exitwhen u==null
    endloop   
    
    // Load data of the killer
    call DTR_LoadTableData(KillerKey, TargetKey)
    
    set udg_DTR_Source = Killer
    set udg_DTR_Target = Target
    
    set udg_DTR_TrackEvent = 0.0 
    set udg_DTR_TrackEvent = 2.0
    set udg_DTR_TrackEvent = 0.0 
    
    // Reset data
    
    set g = udg_DTR_TargetPairGroup[TargetId]
    set u = FirstOfGroup(g)
    loop              
        set SourceId = GetUnitUserData(u)

        set udg_DTR_OverallContribution[SourceId] = 0.0
        set udg_DTR_SpellContribution[SourceId] = 0.0
        set udg_DTR_PhysContribution[SourceId] = 0.0
        
        call GroupRemoveUnit(g, u)
        set u = FirstOfGroup(g)
        exitwhen u==null
    endloop

    set udg_DTR_TopContribution = 0.0
    set udg_DTR_TopSpellContribution = 0.0
    set udg_DTR_TopPhysContribution = 0.0
    
    set udg_DTR_TotalDamageTaken = 0.0
    set udg_DTR_TotalUnitDamage = 0.0
    
    set udg_DTR_TotalSpellDamageTaken = 0.0
    set udg_DTR_TotalSpellDamage = 0.0
    
    set udg_DTR_TotalPhysDamageTaken = 0.0
    set udg_DTR_TotalPhysicalDamage = 0.0

    set udg_DTR_Source = null
    set udg_DTR_Target = null
    
    call DTR_ClearTableData(TargetKey)
    
    call DestroyGroup(udg_DTR_TargetPairGroup[TargetId])    
    set udg_DTR_TargetPairGroup[TargetId] = null
    
    call GroupClear(udg_DTR_Sources)

    set g = null
    
    set Killer = null
    set Target = null
    
    return false
endfunction

function DTR_BeforeUnitDamage takes nothing returns boolean
    // Assign locals
    local unit Source = udg_DamageEventSource
    local unit Target = udg_DamageEventTarget
    local integer TargetKey = GetHandleId(Target)
    local real TargetHP = GetUnitState(Target, UNIT_STATE_LIFE)
    
    // Validate whether source and/or target registered
    if DTR_ValidateUnit(Source, Target) then
        set Source = null
        set Target = null
        return false
    endif

    // Save HP value before taking damage for comparison later
    call SaveReal(udg_DTR_Table, 3, TargetKey, TargetHP)

    set Source = null
    set Target = null
    return false
endfunction

function DTR_OnUnitDamage takes nothing returns boolean
    // Assign locals
    local unit Source = udg_DamageEventSource
    local unit Target = udg_DamageEventTarget
    local integer SourceKey = GetHandleId(Source)
    local integer TargetKey = GetHandleId(Target)
    local integer SourcePId = GetPlayerId(GetOwningPlayer(Source))
    local integer TargetPId = GetPlayerId(GetOwningPlayer(Target))
    local integer TargetId = GetUnitUserData(Target)
    local real TempDmg = udg_DamageEventAmount
    local real TargetHP = 0.0

    // Validate whether source and/or target registered
    if DTR_ValidateUnit(Source, Target) then
        set Source = null
        set Target = null
        return false
    endif

    // -> Load data <-    
    set TargetHP = LoadReal(udg_DTR_Table, 3, TargetKey)

    // Damage Correction when damage value is over current HP value
    if TargetHP <= TempDmg then
        set TempDmg = TargetHP
    endif
    
    call DTR_LoadTableData(SourceKey, TargetKey)
    
    // Prepares a group to contain all the damage sources
    if udg_DTR_TargetPairGroup[TargetId] == null then
        set udg_DTR_TargetPairGroup[TargetId] = CreateGroup()
    endif
    
    // Add the source if its not already in the group
    if not IsUnitInGroup(Source, udg_DTR_TargetPairGroup[TargetId]) then
        call GroupAddUnit(udg_DTR_TargetPairGroup[TargetId], Source)
    endif

    // Start a timer if auto clean is on
    if udg_DTR_TotalDamageTaken == 0.0 and udg_DTR_AutoCleanup == true then
        
        // New entry
        set udg_DTR_ActivePairs = udg_DTR_ActivePairs + 1
        set udg_DTR_TimeCounter[udg_DTR_ActivePairs] = 0.0
        set udg_DTR_SourceArr[udg_DTR_ActivePairs] = Source
        set udg_DTR_TargetArr[udg_DTR_ActivePairs] = Target
        
        if udg_DTR_ActivePairs == 1 then
            call TimerStart(udg_DTR_Timer, udg_DTR_TimeInterval, true, function DTR_TimerCallback)
        endif
    endif

    // Update Data

    call SaveReal(udg_DTR_Table, 4, TargetKey, 0.0) // Reset the counter to prolong its timer

    set udg_DTR_TotalPlayerDamage[SourcePId] = udg_DTR_TotalPlayerDamage[SourcePId] + TempDmg
    set udg_DTR_TotalPlayerDamageT[TargetPId] = udg_DTR_TotalPlayerDamageT[TargetPId] + TempDmg
    
    set udg_DTR_TotalDamageTaken = udg_DTR_TotalDamageTaken + TempDmg
    call SaveReal(udg_DTR_Table, 0, TargetKey, udg_DTR_TotalDamageTaken)

    set udg_DTR_TotalUnitDamage = udg_DTR_TotalUnitDamage + TempDmg
    call SaveReal(udg_DTR_Table, TargetKey, SourceKey, udg_DTR_TotalUnitDamage)

    if udg_IsDamageSpell == true then        
        set udg_DTR_TotalSpellDamageTaken = udg_DTR_TotalSpellDamageTaken + TempDmg
        call SaveReal(udg_DTR_Table, 1, TargetKey, udg_DTR_TotalSpellDamageTaken)
 
        set udg_DTR_TotalSpellDamage = udg_DTR_TotalSpellDamage + TempDmg
        call SaveReal(udg_DTR_Table, TargetKey + 100000, SourceKey, udg_DTR_TotalSpellDamage)

        set udg_DTR_TotalPlayerSpellDamage[SourcePId] = udg_DTR_TotalPlayerSpellDamage[SourcePId] + TempDmg
        set udg_DTR_TotalPlayerSpellDamageT[TargetPId] = udg_DTR_TotalPlayerSpellDamageT[TargetPId] + TempDmg

    else
        set udg_DTR_TotalPhysDamageTaken = udg_DTR_TotalPhysDamageTaken + TempDmg
        call SaveReal(udg_DTR_Table, 2, TargetKey, udg_DTR_TotalPhysDamageTaken)

        set udg_DTR_TotalPhysicalDamage = udg_DTR_TotalPhysicalDamage + TempDmg
        call SaveReal(udg_DTR_Table, TargetKey + 200000, SourceKey, udg_DTR_TotalPhysicalDamage)

        set udg_DTR_TotalPlayerPhysDamage[SourcePId] = udg_DTR_TotalPlayerPhysDamage[SourcePId] + TempDmg
        set udg_DTR_TotalPlayerPhysDamageT[TargetPId] = udg_DTR_TotalPlayerPhysDamageT[TargetPId] + TempDmg

    endif        

    set udg_DTR_Source = Source
    set udg_DTR_Target = Target

    set udg_DTR_TrackEvent = 0.0
    set udg_DTR_TrackEvent = 1.0
    set udg_DTR_TrackEvent = 0.0 

    // Reset data
    set udg_DTR_TotalDamageTaken = 0.0
    set udg_DTR_TotalUnitDamage = 0.0
    
    set udg_DTR_TotalSpellDamageTaken = 0.0
    set udg_DTR_TotalSpellDamage = 0.0
    
    set udg_DTR_TotalPhysDamageTaken = 0.0
    set udg_DTR_TotalPhysicalDamage = 0.0
    
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
    
    set udg_DTR_GetData = CreateTrigger()
    call TriggerAddCondition( udg_DTR_GetData, Condition( function GetDamageTrackerData ) )

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

