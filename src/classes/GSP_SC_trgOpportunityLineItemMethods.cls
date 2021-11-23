/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, June, 2020
 */
public with sharing class GSP_SC_trgOpportunityLineItemMethods
{
	public static void UpdateScheduleSize(Set<Id> opportunityLineItemSet)
	{
		GSP_SC_ScheduleHelper.ModifyScheduleStructure(opportunityLineItemSet, true);
	}
	
	public static void UpdateRevenueDates(Map<Id, OpportunityLineItem>  opportunityLineItemMap)
	{
		if ((Schema.sObjectType.Revenue_Schedule__c.isAccessible() &&
			Schema.sObjectType.Revenue_Schedule__c.isCreateable() &&
			Schema.sObjectType.Revenue_Schedule__c.isUpdateable() &&
			Schema.sObjectType.Revenue_Schedule__c.isDeletable()) ||
			test.isRunningTest())
		{
			Map<Id, List<Revenue_Schedule__c>> opportunityLineItemKeyedRevenueScheduleMap = new Map<Id, List<Revenue_Schedule__c>>();
			Set<Id> opportunitySet = new Set<Id>();
			Map<Id, OpportunityLineItem> opportunityLineItemSearchMap = new Map<Id, OpportunityLineItem>();
			List<Revenue_Schedule__c> revenueScheduleCache = new List<Revenue_Schedule__c>();
			List<Schedule_Settings__c> scheduleSettings = Schedule_Settings__c.getAll().values();
			Integer nGlobalOffset = 1;
			String strGlobalInterval = 'M';

			if (!scheduleSettings.isEmpty() && !String.isEmpty(scheduleSettings.get(0).Global_Schedule_Interval__c))
			{
				try
				{
					String strInterval = scheduleSettings.get(0).Global_Schedule_Interval__c.left(1);
					Integer nOffset = Integer.valueOf(scheduleSettings.get(0).Global_Schedule_Interval__c.mid(1, 10));
					if (strInterval == 'Y' ||
						strInterval == 'M' ||
						strInterval == 'D')
					{
						strGlobalInterval = strInterval;
						nGlobalOffset = nOffset;
					}
				}
				catch (Exception ex){}
			}
			
			for (OpportunityLineItem opportunityLineItem : opportunityLineItemMap.values())
			{
				opportunitySet.add(opportunityLineItem.OpportunityId);
			}
			
			for (Opportunity opportunity : [
				SELECT
					Id, (
					SELECT
						Id,
						Revenue_Start_Date__c,
						PricebookEntry.Product2.Schedule_Interval_Override__c
					FROM
						OpportunityLineItems
					WHERE
						Id IN :opportunityLineItemMap.keySet()), (
					SELECT
						Id,
						Account__c,
						Account_Owner__c,
						Budget__c,
						Product__c,
						Revenue_Schedule_Date__c,
						Opportunity_Line_Item_Id__c
					FROM
						Revenue_Schedules__r
					WHERE
						Opportunity_Line_Item_Id__c IN :opportunityLineItemMap.keySet()
					ORDER BY
						Opportunity_Line_Item_Id__c, Revenue_Schedule_Date__c)
				FROM
					Opportunity
				WHERE
					Id IN :opportunitySet])
			{
				for (OpportunityLineItem opportunityLineItem : opportunity.OpportunityLineItems)
				{
					opportunityLineItemSearchMap.put(opportunityLineItem.Id, opportunityLineItem);
					System.assertEquals(true, opportunityLineItemMap.containsKey(opportunityLineItem.Id));
					opportunityLineItemKeyedRevenueScheduleMap.put(opportunityLineItem.Id, new List<Revenue_Schedule__c>());
				}
				
				for (Revenue_Schedule__c revenueSchedule : opportunity.Revenue_Schedules__r)
				{
					System.assertEquals(true, opportunityLineItemKeyedRevenueScheduleMap.containsKey(revenueSchedule.Opportunity_Line_Item_Id__c));
					opportunityLineItemKeyedRevenueScheduleMap.get(revenueSchedule.Opportunity_Line_Item_Id__c).add(revenueSchedule);
				}
			}
	
			for (Id id : opportunityLineItemKeyedRevenueScheduleMap.keySet())
			{
				if (opportunityLineItemMap.containsKey(id))
				{
					OpportunityLineItem opportunityLineItem = opportunityLineItemSearchMap.get(id);
					Integer nLocalOffset = nGlobalOffset;
					String strLocalInterval = strGlobalInterval;
					if (opportunityLineItem.PricebookEntry.Product2.Schedule_Interval_Override__c != null)
					{
						try
						{
							String strInterval = opportunityLineItem.PricebookEntry.Product2.Schedule_Interval_Override__c.left(1);
							Integer nOffset = Integer.valueOf(opportunityLineItem.PricebookEntry.Product2.Schedule_Interval_Override__c.mid(1, 10));
							if (strInterval == 'Y' ||
								strInterval == 'M' ||
								strInterval == 'D')
							{
								strLocalInterval = strInterval;
								nLocalOffset = nOffset;
							}
						}
						catch (Exception ex){}
					}

					OpportunityLineItem oldOpportunityLineItem = (OpportunityLineitem)trigger.oldMap.get(opportunityLineItem.Id);
					Integer days = oldOpportunityLineItem.Revenue_Start_Date__c.daysBetween(opportunityLineItem.Revenue_Start_Date__c);
					if (opportunityLineItemKeyedRevenueScheduleMap.containsKey(id) &&
						!opportunityLineItemKeyedRevenueScheduleMap.get(id).isEmpty())
					{
						Date dtSchedule,
							baseSchedule;
						for (Integer i = 0; i < opportunityLineItemKeyedRevenueScheduleMap.get(id).size(); i++)
						{
							if (Schema.sObjectType.Revenue_Schedule__c.fields.Revenue_Schedule_Date__c.isUpdateable())
							{
								Revenue_Schedule__c revenueSchedule = opportunityLineItemKeyedRevenueScheduleMap.get(id).get(i);
								if (i == 0)
								{
									revenueSchedule.Revenue_Schedule_Date__c += days;
									baseSchedule = revenueSchedule.Revenue_Schedule_Date__c;
								}
								else
								{
									revenueSchedule.Revenue_Schedule_Date__c = dtSchedule;
								}
								
								if (strLocalInterval == 'D')
								{
									dtSchedule = baseSchedule.addDays(nLocalOffset * i + 1);
								}
								else if (strLocalInterval == 'M')
								{
									dtSchedule = baseSchedule.addMonths(nLocalOffset * i + 1);
								}
								else if (strLocalInterval == 'Y')
								{
									dtSchedule = baseSchedule.addYears(nLocalOffset * i + 1);
								}
								revenueScheduleCache.add(revenueSchedule);
							}
						}
					}
				}
			}
			if (!revenueScheduleCache.isEmpty())
			{
				if (Schema.sObjectType.Revenue_Schedule__c.isUpdateable() ||
					test.isRunningTest())
				{
					update revenueScheduleCache;
				}
			}
			GSP_SC_Schedulehelper.LinkBudgets(revenueScheduleCache, opportunityLineItemKeyedRevenueScheduleMap, true);
		}
	}
	
	private static Set<Id> DeleteRevenueSchedules(List<OpportunityLineItem> opportunityLineItemList)
	{
		Set<Id> opportunitySet = new Set<Id>();
		Set<Id> budgetSet = new Set<Id>();
		Set<Id> opportunityLineItemSet = new Set<Id>();			
		List<Revenue_Schedule__c> revenueScheduleList = new List<Revenue_Schedule__c>();
		for (OpportunityLineItem opportunityLineItem : opportunityLineItemList)
		{
			opportunityLineItemSet.add(opportunityLineItem.Id);
			opportunitySet.add(opportunityLineItem.OpportunityId);
		}
			
		if (Schema.sObjectType.Revenue_Schedule__c.isAccessible())
		{
			for (Opportunity opportunity : [
				SELECT
					Id, (
					SELECT
						Budget__c
					FROM
						Revenue_Schedules__r)
				FROM
					Opportunity
				WHERE
					Id IN :opportunitySet])
			{
				for (Revenue_Schedule__c revenueSchedule : opportunity.Revenue_Schedules__r)
				{
					budgetSet.add(revenueSchedule.Budget__c);
				}
			}
			
			for (Revenue_Schedule__c revenueSchedule :[
				SELECT
					Id,
					Budget__c
				FROM
					Revenue_Schedule__c
				WHERE
					Opportunity_Line_Item_Id__c IN :opportunityLineItemSet])
			{
				revenueScheduleList.add(revenueSchedule);
			}
			
			try
			{
				if (Schema.sObjectType.Revenue_Schedule__c.isDeletable() ||
					test.isRunningTest())
				{
					delete revenueScheduleList;
					// Recalculate old budgets
					if (!budgetSet.isEmpty())
					{
						GSP_SC_BudgetHelper.RollUpScheduleValues(budgetSet);
					}
				}
			}
			catch (Exception ex){}
		}
		return opportunityLineItemSet;
	}
	
	public static void UpdateScheduleClinics(Map<Id, OpportunityLineItem> opportunityLineItemMap)
	{
		List<Revenue_Schedule__c> revenueScheduleCache = new List<Revenue_Schedule__c>();
		Map<Id, List<Revenue_Schedule__c>> revenueScheduleMap = new Map<Id, List<Revenue_Schedule__c>>(); 
		for (Id opportunityLineItemId : opportunityLineItemMap.keySet())
		{
			revenueScheduleMap.put(opportunityLineItemId, new List<Revenue_Schedule__c>());
		}
		
		for (Revenue_Schedule__c revenueSchedule : [
			SELECT
				Id,
				Revenue_Schedule_Date__c,
				Account__c,
				Account_Owner__c,
				Clinic__c,
				Clinic_Budget__c,
				Budget__c,
				Opportunity_Line_Item_Id__c
			FROM
				Revenue_Schedule__c
			WHERE
				Opportunity_Line_Item_Id__c IN :opportunityLineItemMap.keySet()])
		{
			System.assertEquals(true, revenueScheduleMap.containsKey(revenueSchedule.Opportunity_Line_Item_Id__c));
			revenueSchedule.Clinic__c = opportunityLineItemMap.get(revenueSchedule.Opportunity_Line_Item_Id__c).Clinic__c;
			revenueScheduleMap.get(revenueSchedule.Opportunity_Line_Item_Id__c).add(revenueSchedule);
			revenueScheduleCache.add(revenueSchedule);
		}
		
		GSP_SC_ScheduleHelper.LinkBudgets(revenueScheduleCache, revenueScheduleMap, true);
	}
	
	public static void DeleteSchedules(List<OpportunityLineItem> opportunityLineItemList)
	{
		DeleteRevenueSchedules(opportunityLineItemList);
	}
}