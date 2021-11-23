/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, June, 2020
 */
trigger GSP_SC_Opportunity on Opportunity (after delete, after insert, after update, before delete, before insert, before update)
{
	if (!GSP_SC_TriggerContext.DisableOpportunityTriggers && !GSP_SC_TriggerContext.DisableAllTriggers)
	{
		Boolean bDisableCloseDateChanges = false;
		Schedule_Settings__c scheduleSetting = Schedule_Settings__c.getInstance('Default');
		if (scheduleSetting != null)
		{
			bDisableCloseDateChanges = scheduleSetting.Disable_Close_Date_Updates__c;
		}
		if (trigger.isBefore)
		{
			if (trigger.isUpdate)
			{
				Map<Id, Date> opportunityCloseDateMap = new Map<Id, Date>();
				Map<Id, Opportunity> opportunityStatusMap = new Map<Id, Opportunity>();
				for (Opportunity opportunity : trigger.new)
				{
					Opportunity oldOpportunity = trigger.oldMap.get(opportunity.Id);
					if (opportunity.isClosed && !oldOpportunity.isClosed)
					{
						// Moving from Open to Closed Won
						if (opportunity.isWon)
						{
							if (!bDisableCloseDateChanges &&
								!GSP_SC_TriggerContext.DisableOpportunityClosedWonTriggers)
							{
								// Closed Won from Open (possible Close Date change)
								opportunityCloseDateMap.put(opportunity.Id, opportunity.CloseDate);
							}
						}
						else
						{
							// Closed Lost from Open - Delete Schedules
						}
					}
					else if (opportunity.isClosed && oldOpportunity.isClosed)
					{
						if (opportunity.isWon && !oldOpportunity.isWon)
						{
							// Closed Won from Closed Lost - Rebuild schedules
						}
						else if (!opportunity.isWon && oldOpportunity.isWon)
						{
							// Closed Lost from Closed Won - Delete schedules
						}
					}
					
				}
				if (!opportunityCloseDateMap.isEmpty())
				{
					GSP_SC_trgOpportunityMethods.CheckCloseDate(opportunityCloseDateMap);
					GSP_SC_TriggerContext.DisableOpportunityClosedWonTriggers = true;
				}
			}
			if (trigger.isDelete)
			{
				GSP_SC_trgOpportunityMethods.DeleteSchedules(trigger.oldMap.keySet());
			}
		}
		else
		{
			if (trigger.isUpdate)
			{
				Map<Id, opportunity> opportunityCloseMap = new Map<Id, Opportunity>();
				Set<Id> opportunity2DeleteSet = new Set<Id>();
				Set<Id> opportunityRebuildSet = new Set<Id>();
				Set<Id> opportunityOwnerSet = new Set<Id>();
				Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
				for (Opportunity opportunity : trigger.new)
				{
					Opportunity oldOpportunity = trigger.oldMap.get(opportunity.Id);
					if (opportunity.isClosed)
					{
						if (!oldOpportunity.isClosed)
						{
							if (opportunity.isWon)
							{
								if (!bDisableCloseDateChanges)
								{
									// Closed Won from Open
									opportunityCloseMap.put(opportunity.Id, opportunity);
								}
							}
							else
							{// Closed Lost from Open
								opportunity2DeleteSet.add(opportunity.Id);
							}
						}
						else
						{
							if (opportunity.isWon && !oldOpportunity.IsWon)
							{// Closed Won from Closed Lost
								opportunityRebuildSet.add(opportunity.Id);
							}
							else if (!opportunity.IsWon && oldOpportunity.IsWon)
							{// Closed Lost from Closed Won
								opportunity2DeleteSet.add(opportunity.Id);
							}
						}
					}
					else
					{
						// Open opportunity
						if (oldOpportunity.isWon)
						{// Open from Closed Won
							
						}
						else if (oldOpportunity.isClosed && !oldOpportunity.IsWon)
						{// Open from Closed Lost
							opportunityRebuildSet.add(opportunity.Id);
						}
					}
					
					if (opportunity.Amount != oldOpportunity.Amount ||
						(opportunity.Probability != oldOpportunity.Probability &&
						!opportunity.isClosed))
					{
						opportunityCloseMap.put(opportunity.Id, opportunity);
					}
					if (opportunity.CloseDate != oldOpportunity.CloseDate &&
						!bDisableCloseDateChanges)
					{
						opportunityMap.put(opportunity.Id, opportunity);
					}
					
/*					if (opportunity.Ownerid != oldOpportunity.OwnerId)
					{
						opportunityOwnerSet.add(opportunity.Id);
					}*/
				}
				
				if (!opportunityMap.isEmpty())
				{
					GSP_SC_trgOpportunityMethods.OffsetScheduleDates(opportunityMap, trigger.oldMap);
				}
				
				if (!opportunity2DeleteSet.isEmpty())
				{
					GSP_SC_trgOpportunityMethods.DeleteSchedules(opportunity2DeleteSet);
				}
				
				if (!opportunityCloseMap.isEmpty())
				{
					GSP_SC_trgOpportunityMethods.UpdateTotals(opportunityCloseMap);
				}
				
				if (!opportunityRebuildSet.isEmpty())
				{
					GSP_SC_trgOpportunityMethods.RebuildSchedules(opportunityRebuildSet);
				}
				
/*				if (!opportunityOwnerSet.isEmpty())
				{
					GSP_SC_trgOpportunityMethods.ChangeOwner(opportunityOwnerSet);
				}*/
			}	
		}
	}    
}