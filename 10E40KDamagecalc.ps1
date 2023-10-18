<#
################################
	ScriptName: 
	Warhammer 40,000 10th Edition Damage Calculator

	Author: 
	Mike "Chilli" Carnie
	
	Description:
	This script will collate variables relating the the attacking unit and the targeted unit and give the "average" number of total hits, wounds inflicted, failed save and damage inflicted.
	
	Usage:
	Just call up the name of the script and it will prompt for the required variables to be entered
	
	License:
	You are free to use, run, modify and redistribute this script in full or in part, so long as appropriate credit is assigned.
	This script is supplied as-is and No liability is accepted for any errors or issues that arise from running this script. Please review the full script content before running.
	
	Future Planned improvements/additions
	- Replace variable declarations with user prompts
	- Build in a calculation for determining number of models killed when FNP is in play
	
	Version History:
	- Version 0.1 (18/10/23): First Draft - All variables at this time are manually specified for initial runs
	  Please note that this version does not currently allow for the accurate calculation of models killed when the target unit has FNP - only for if the unit is a single model
	  


################################
#>



### Clear out all variables ###
Get-Variable | ForEach-Object { Clear-Variable -Name $_.Name }

### Declare variables - will be done as prompts unless specified ###

# Hit Re-rolls - None, All, 1
$HitReRolls = None										
# Wound Re-rolls - None, All, 1
$WoundReRolls = None
# Save Re-rolls - None, All, 1
$SaveReRolls = None
$AttackingModels = 10
$Attacks = 2
$Shots = $AttackingModels * $Attacks     #noprompt
$BS = 4 												
$Torrent = $false
$WoundRoll = 4
$Damage = 2
$ExtraDamage = 0
$CrithitRoll = 6
$CritWoundRoll = 6
$IsLethalHits = $true
$IsSustainedHits = $true
$IsDevastatingWounds = $False
$SustainedX = 1
$ToHit = (7-$BS)/6						#noprompt
$ToWound = (7-$WoundRoll)/6				#noprompt			
$ToCritHit = (7-$CritHitRoll)/6			#noprompt
$ToCritWound = (7-$CritWoundRoll)/6		#noprompt
$Save = 3
$FNP = 5
$ToSaveFNP = (7-$FNP)/6					#noprompt
$WoundsPerModel = 2
$ModelsInTarget = 10

# Damage Mitigation - None, 1, Half
$DamageMitigation = None
$AP = 2
$HasCover = $true
$Invuln = 5
$FNP = 0

# Save calculations
$coverValue = if ($hascover -and $save -gt 3) {-1} else {0}
if (($save + $AP + $coverValue) -ge $invuln) { $netsave = $invuln } else { $netsave = $save + $AP + $coverValue }
$saveroll = (7-$netsave)/6

### Number of Hit Calculations ###
# Normal Hits
$AllHits = $Shots * $ToHit  
# Working out how many dice available for rerolls
$Misses = $Shots - $AllHits
# Determines the number of additional hits with full rerolls
if ($HitReRolls -eq "All") {$RRHits = $Misses * $ToHit}
# Determines the number of additional hits with reroll 1s
if ($HitReRolls -eq "1") { $RRHits = ($Shots/6) * $ToHit}
# Determine number of crit hits with full rerolls
if ($HitReRolls -eq "All") {$RRCritHits = $Misses * $ToCritHit}
# Determine the number of crit hits with reroll 1s
if ($HitReRolls -eq "1" ) { $RRCritHits = ($Shots/6) * $ToCritHit}
# Calculate the number of hits that will count as critical hits
$CritHits = ($Shots * $ToCritHit) + $RRCritHits			
# Calculate the number of Sustained Hits
if $IsSustainedHits { $SustainedHits = $CritHits * $SustainedX }
if $IsLethalHits { $LethalHits = $crithits }

# Calculate final Hit value. Note that if has Lethal hits, this will remove that value for use in the wounds calculation later
$Hits = $AllHits - $LethalHits + $SustainedHits + $RRHits 

### Number of Wound Calculations ###

# Normal wounds
$AllWounds = $Hits * $ToWound
# Declare value of failed wounds for rerolls
$FailedWounds = $Hits - $AllWounds
# Determine the number of additional wounds with full rerolls
if ($WoundReRolls -eq "All") { $RRWounds = $FailedWounds * $ToWound }
# Determine the number of additional wounds with reroll 1s
if ($WoundRolls -eq "1") { $RRWounds = ($AllWounds/6) * $ToWound }
# Determine number of crit wounds with full rerolls
if ($WoundReRolls -eq "All") { $RRCritWounds = $FailedWounds * $ToCritWound}
# Determine the number of crit hits with reroll 1s
if ($WoundReRolls -eq "1") { $RRCritWounds = ($Hits/6) * $ToCritwound }
# Calculate the number of hits that will count as critical wounds
$CritWounds = ($Hits * $ToCritWound) + $RRCritWounds
if $IsDevastatingWounds { $DevastatingWounds = $CritWounds }

# Calculate final wounds value. This will add on the previously removed lethal hits and also remove devastating wounds for using later
$Wounds = $AllWounds - $DevastatingWounds + $LethalHits


### Number of failed save calculations ###

$SuccessfulSaves = $Wounds * $saveroll
$FailedSaves = $Wounds - $SuccessfulSaves

# Determine number of additional saves with reroll options
if ($SaveRerolls -eq "All" ) { $SuccessfulSaves = ($FailedSaves * $Saveroll) + $SuccessfulSaves; $FailedSaves = $Wounds - $SuccessfulSaves}
if ($SaveRerolls -eq "1" ) { $SuccessfulSaves = (($Wounds/6) * $Saveroll) + $SuccessfulSaves; $FailedSaves = $Wounds - $SuccessfulSaves}

# Give final total of failed saves
$FailedSaves = $FailedSaves + $DevastatingWounds

### Damage Calculation ###

# Halve or reduce damage to a minumum of 1 varable adjustments
if ($DamageMitigation -eq "Half" -and $Damage -gt 1) { $Damage= [Math]::Ceiling($Damage/2) }
if ($DamageMitigation -eq "1" and $Damage -gt 1) { $Damage = $Damage - 1  }
if ($Damage -lt 1) { $Damage = 1 }

# Add Extra Damage that is unaffected by damage mitigation
$Damage = $Damage + $ExtraDamage

$TotalWoundsInflicted = $FailedSaves * $Damage
$FNPSaves = $TotalWoundsInflicted * $ToSaveFNP
if ($FNP -gt 0) { $TotalWoundsInflicted = $TotalWoundsInflicted - $FNPSaves }

$FailedSavesToKill = [Math]::Ceiling($WoundsPerModel / $Damage)
$ModelsKilled = $FailedSaves / $FailedSavesToKill

$FNPText = ""
if ($FNP -gt 0) { $FNPText = "after FNP Rolls." }

Write-Host "The Attack has inflicted a total of $FailedSaves failed saves, inflicting a total of $Damage damage. It will have killed a total of $ModelsKilled models from this attack $FNPText"
if ($ModelsKilled -ge $ModelsInTarget) { write-host "The Target unit has been wiped out/Destroyed" }
if ($FNP -gt 0 -and $ModelsinTarget -gt 1) {Write-Host "Please note that FNP calculations have only been made on the assumption of a single model in the target and this script cannot currently determine accurate kill counts for when FNP is in play for a unit with more than a single model" }
