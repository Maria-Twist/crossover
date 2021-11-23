/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, June, 2020
 */
trigger GSP_SC_OpportunityLineItem on OpportunityLineItem (after delete, after insert, after update, before delete, before insert, before update)
{
	if (!GSP_SC_TriggerContext.DisableOpportunityLineItemTriggers && !GSP_SC_TriggerContext.DisableAllTriggers)
	{
		if (trigger.isBefore)
		{
			
		}
		else
		{
			if (trigger.isInsert)
			{
				GSP_SC_trgOpportunityLineItemMethods.UpdateScheduleSize(trigger.newMap.keySet());
			}
			else if (trigger.isUpdate)
			{
				List<OpportunityLineItem> opportunityLineItemList = new List<OpportunityLineItem>();
				Set<Id> opportunityLineItemRevenueProjectionSet = new Set<Id>();
				Map<Id, OpportunityLineItem>  opportunityLineItemMap = new Map<Id, OpportunityLineItem>();
				Map<Id, OpportunityLineItem> opportunityLineItemClinicMap = new Map<Id, OpportunityLineItem>(); 
				
				Set<Id> opportunityLineItemSet = new Set<Id>();
				
				for (OpportunityLineItem opportunityLineItem : trigger.new)
				{
					OpportunityLineItem oldOpportunityLineItem = trigger.oldMap.get(opportunityLineItem.Id);
					
					if (opportunityLineItem.Revenue_Months__c != oldOpportunityLineItem.Revenue_Months__c ||
						opportunityLineItem.Quantity != oldOpportunityLineItem.Quantity ||
						opportunityLineItem.TotalPrice != oldOpportunityLineItem.TotalPrice ||
						opportunityLineItem.Discount != oldOpportunityLineItem.Discount ||
						opportunityLineItem.Revenue_Projection_Method__c != oldOpportunityLineItem.Revenue_Projection_Method__c ||
						(opportunityLineItem.Revenue_Start_Date__c == null && oldOpportunityLineItem.Revenue_Start_Date__c != null) ||
						(opportunityLineItem.Revenue_Start_Date__c != null && oldOpportunityLineItem.Revenue_Start_Date__c == null))
					{
						opportunityLineItemSet.add(opportunityLineItem.Id);
					}
					
					if (opportunityLineItem.Revenue_Start_Date__c != oldOpportunityLineItem.Revenue_Start_Date__c &&
						opportunityLineItem.Revenue_Start_Date__c != null &&
						oldOpportunityLineItem.Revenue_Start_Date__c != null)
					{
						opportunityLineItemMap.put(opportunityLineItem.Id, opportunityLineItem);
					}
					if (opportunityLineItem.Clinic__c != oldOpportunityLineItem.Clinic__c)
					{
						opportunityLineItemClinicMap.put(opportunityLineItem.Id, opportunityLineItem);
					}
				}
				
				if (!opportunityLineItemSet.isEmpty())
				{
					GSP_SC_trgOpportunityLineItemMethods.UpdateScheduleSize(opportunityLineItemSet);
				}
				if (!opportunityLineItemMap.isEmpty())
				{
					GSP_SC_trgOpportunityLineItemMethods.UpdateRevenueDates(opportunityLineItemMap);
				}
				if (!opportunityLineItemClinicMap.isEmpty())
				{
					GSP_SC_trgOpportunityLineItemMethods.UpdateScheduleClinics(opportunityLineItemClinicMap);
				}
			}
			else if (trigger.isDelete)
			{
				GSP_SC_trgOpportunityLineItemMethods.DeleteSchedules(trigger.old);
			}
		}
	}    
}