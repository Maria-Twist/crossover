/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, June, 2020
 */
public with sharing class GSP_SC_trgOpportunityMethods
{
	public static void DeleteSchedules(Set<Id> opportunitySet)
	{
		if (Schema.sObjectType.OpportunityLineItem.isAccessible() &&
			Schema.sObjectType.Revenue_Schedule__c.isAccessible() ||
			test.isRunningTest())
		{
			Set<Id> budgetSet = new Set<Id>();
			List<Revenue_Schedule__c> revenueScheduleCache = new List<Revenue_Schedule__c>();
			Map<Id, OpportunityLineItem> opportunityLineItemMap = new  Map<Id, OpportunityLineItem>([
				SELECT
					Id
				FROM
					OpportunityLineItem
				WHERE
					OpportunityId IN :opportunitySet]);
				
			for (Revenue_Schedule__c revenueSchedule : [
				SELECT
						Id,
						Budget__c
					FROM
						Revenue_Schedule__c
					WHERE
						Opportunity_Line_Item_Id__c IN :opportunityLineItemMap.keySet()])
			{
				if (revenueSchedule.Budget__c != null)
				{
					budgetSet.add(revenueSchedule.Budget__c);
				}
				revenueScheduleCache.add(revenueSchedule);
			}
				
			if (!revenueScheduleCache.isEmpty())
			{
				try
				{
					if (Schema.sObjectType.Revenue_Schedule__c.isDeletable() ||
						test.isRunningTest())
					{
						delete revenueScheduleCache;
						if (!budgetSet.isEmpty())
						{
							GSP_SC_BudgetHelper.RollUpScheduleValues(budgetSet);
						}
					}
				}
				catch (Exception ex){}
			}
		}
	}
	
	public static void OffsetScheduleDates(Map<Id, Opportunity> opportunityMap, Map<Id, Opportunity> oldOpportunityMap)
	{
		if (Schema.sObjectType.OpportunityLineItem.isAccessible() ||
			test.isRunningTest())
		{
			Map<Id, Integer> opportunityCloseDateOffsetMap = new Map<Id, Integer>();
			List<OpportunityLineItem> opportunityLineItemCache = new List<OpportunityLineItem>();
			for (Opportunity opportunity : opportunityMap.values())
			{
				Opportunity oldOpportunity = oldOpportunityMap.get(opportunity.Id);
				opportunityCloseDateOffsetMap.put(opportunity.Id, oldOpportunity.CloseDate.daysBetween(opportunity.CloseDate));
			}
				
			for (Opportunity opportunity: [
				SELECT
					Id, (
					SELECT
						Revenue_Start_Date__c
					FROM
						OpportunityLineItems
					WHERE
						Revenue_Start_Date__c != null)
				FROM
					Opportunity
				WHERE
					Id IN :opportunityCloseDateOffsetMap.keySet()])
			{
				if (opportunityCloseDateOffsetMap.containsKey(opportunity.Id))
				{
					for (OpportunityLineItem opportunityLineItem : opportunity.OpportunityLineItems)
					{
						if (Schema.sObjectType.OpportunityLineItem.fields.Revenue_Start_Date__c.isUpdateable() ||
							test.isRunningTest())
						{
							opportunityLineItem.Revenue_Start_Date__c += opportunityCloseDateOffsetMap.get(opportunity.Id);
							opportunityLineItemCache.add(opportunityLineItem);
						}
					}
				}
			}
			if (!opportunityLineItemCache.isEmpty() &&
				(Schema.sObjectType.OpportunityLineItem.isUpdateable() ||
				test.isRunningTest()))
			{
				update opportunityLineItemCache;
			}
		}
	}
	
/*	public static void ChangeOwner(Set<Id> opportunitySet)
	{
		if ((Schema.sObjectType.OpportunityLineItem.isAccessible() &&
			Schema.sObjectType.Revenue_Schedule__c.isAccessible()) ||
			test.isRunningTest())
		{
			Map<Id, List<Revenue_Schedule__c>> lineItemKeyedScheduleMap = new Map<Id, List<Revenue_Schedule__c>>();
			List<Revenue_schedule__c> revenueScheduleCache = new List<Revenue_Schedule__c>();
			for (Opportunity opportunity : [
				SELECT
					Id,
					OwnerId, (
					SELECT
						Id,
//						Opportunity_Owner__c,
						Opportunity_Line_Item_Id__c,
						Revenue_Target__c,
						Revenue_Schedule_Date__c
					FROM
						Revenue_Schedules__r), (
					SELECT
						Id
					FROM
						OpportunityLineItems)
				FROM
					Opportunity
				WHERE
					Id IN :opportunitySet])
			{
				for (OpportunityLineItem opportunityLineItem : opportunity.OpportunityLineItems)
				{
					if (!lineItemKeyedScheduleMap.containsKey(opportunityLineItem.Id))
					{
						lineItemKeyedScheduleMap.put(opportunityLineItem.Id, new List<Revenue_Schedule__c>());
					}
				}
	
				if (Schema.sObjectType.Revenue_Schedule__c.fields.Opportunity_Owner__c.isUpdateable() ||
					test.isRunningTest())
				{
					for (Revenue_Schedule__c revenueSchedule : opportunity.Revenue_Schedules__r)
					{
						System.assertEquals(true, lineItemKeyedScheduleMap.containsKey(revenueSchedule.Opportunity_Line_Item_Id__c));
						lineItemKeyedScheduleMap.get(revenueSchedule.Opportunity_Line_Item_Id__c).add(revenueSchedule);
						
						if (revenueSchedule.Opportunity_Owner__c != opportunity.OwnerId)
						{
							revenueSchedule.Opportunity_Owner__c = opportunity.OwnerId;
							revenueScheduleCache.add(revenueSchedule);
						}
					}
				}
			}
			if (!revenueScheduleCache.isEmpty())
			{
				GSP_SC_ScheduleHelper.LinkRevenueTargets(revenueScheduleCache, lineItemKeyedScheduleMap, true);
			}
		}
	}*/
	
	public static void UpdateTotals(Map<Id, Opportunity> opportunityMap)
	{
		if ((Schema.sObjectType.OpportunityLineItem.isAccessible() &&
			Schema.sObjectType.Revenue_Schedule__c.isAccessible()) ||
			test.isRunningTest())
		{
			Map<Id, List<Revenue_Schedule__c>> opportunityKeyedRevenueScheduleMap = new Map<Id, List<Revenue_Schedule__c>>();
			List<Revenue_Schedule__c> revenueScheduleCache = new LIst<Revenue_Schedule__c>();
			Set<Id> budgetSet = new Set<Id>();

			for (Revenue_Schedule__c revenueSchedule : [
				SELECT
					Opportunity__c,
					Budget__c
				FROM
					Revenue_Schedule__c
				WHERE
					Opportunity__c IN :opportunityMap.keySet()])
			{
				if (revenueSchedule.Budget__c != null)
				{
					budgetSet.add(revenueSchedule.Budget__c);
				}
			}
				
			if (!budgetSet.isEmpty() &&
				(Schema.sObjectType.Revenue_Schedule__c.isUpdateable() ||
				test.isRunningTest()))
			{
				GSP_SC_BudgetHelper.RollUpScheduleValues(budgetSet);
			}
		}
	}
	
	public static void RebuildSchedules(Set<Id> opportunitySet)
	{
		Map<Id, OpportunityLineItem> opportunityLineItemMap = new Map<Id, OpportunityLineItem>([
			SELECT
				Id
			FROM
				OpportunityLineItem
			WHERE
				OpportunityId IN :opportunitySet]);
		GSP_SC_ScheduleHelper.ModifyScheduleStructure(opportunityLineItemMap.keySet(), true);
	}
	
	// Method for adjusting Closed Won Opportunities
	@future
	public static void CheckCloseDate(Map<Id, Date> opportunityCloseDateMap)
	{
		if ((Schema.sObjectType.OpportunityLineItem.isAccessible() &&
			Schema.sObjectType.Revenue_Schedule__c.isAccessible()) ||
			test.isRunningTest())
		{
			List<OpportunityLineItem> opportunityLineItemCache = new List<OpportunityLineItem>();
			List<Revenue_Schedule__c> revenueScheduleCache = new List<Revenue_Schedule__c>();
			for (Opportunity opportunity : [
				SELECT
					Id,
					CloseDate, (
					SELECT
						Revenue_Start_Date__c
					FROM
						OpportunityLineItems)
				FROM
					Opportunity
				WHERE
					Id IN :opportunityCloseDateMap.keySet()])
			{
				if (opportunityCloseDateMap.get(opportunity.Id) != opportunity.CloseDate && !opportunity.OpportunityLineItems.isEmpty())
				{
					integer days = opportunityCloseDateMap.get(opportunity.Id).daysBetween(opportunity.CloseDate);
					for (OpportunityLineItem opportunityLineItem : opportunity.OpportunityLineItems)
					{
						if (Schema.sObjectType.OpportunityLineItem.fields.Revenue_Start_Date__c.isUpdateable() ||
							test.isRunningTest())
						{
							opportunityLineItem.Revenue_Start_Date__c += days;
							opportunityLineItemCache.add(opportunityLineItem);
						}
					}
				}
			}
			if (!opportunityLineItemCache.isEmpty() &&
				(Schema.sObjectType.OpportunityLineItem.isUpdateable() ||
				test.isRunningTest()))
			{
				update opportunityLineItemCache;
			}
			
			for (Revenue_Schedule__c revenueSchedule : [
				SELECT
					Id,
					Revenue_Amount__c,
					Latest_Forecast__c
				FROM
					Revenue_Schedule__c
				WHERE
					Opportunity__c IN : opportunityCloseDateMap.keySet()])
			{
				if (Schema.sObjectType.Revenue_Schedule__c.fields.Latest_Forecast__c.isUpdateable() ||
					test.isRunningTest())
				{
					revenueSchedule.Latest_Forecast__c = revenueSchedule.Revenue_Amount__c;
					revenueScheduleCache.add(revenueSchedule);
				}
			}
			if (!revenueScheduleCache.isEmpty() &&
				(Schema.sObjectType.Revenue_Schedule__c.isUpdateable() ||
				test.isRunningTest()))
			{
				update revenueScheduleCache;
			}
		}
	}
}