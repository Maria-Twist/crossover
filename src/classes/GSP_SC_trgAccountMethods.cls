/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, 21 Jul 2020
 */
public with sharing class GSP_SC_trgAccountMethods
{
	@future
	public static void UpdateScheduleAccountOwners(Set<Id> accountSet, Map<Id, Id> oldOwnerMap)
	{
		Map<Id, List<Revenue_Schedule__c>> opportunityLineItemRevenueScheduleMap = new Map<Id, List<Revenue_Schedule__c>>();
		Map<Id, Invoice_Line__c> invoiceLineCacheMap = new Map<Id, Invoice_Line__c>();
		List<Revenue_Schedule__c> revenueScheduleCache = new List<Revenue_Schedule__c>();
		List<Budget__c> budgetCache = new List<Budget__c>();
		// Old Owner -> New Owner
		Map<Id, Id> oldOwnerKeyedOwnerMap = new Map<Id, Id>();
		Set<String> revIdSet = new Set<String>();
		
		for (Budget__c budget : [
			SELECT
				Id,
				Account__c,
				Account__r.OwnerId,
				OwnerId
			FROM
				Budget__c
			WHERE
				Account__c IN :accountSet])
		{
			budget.Ownerid = budget.Account__r.OwnerId;
			budgetCache.add(budget);
		}
		if (!budgetCache.isEmpty())
		{
			update budgetCache;
		}
		
		for (Opportunity opportunity : [
			SELECT
				Id,
				AccountId,
				Account.OwnerId,
				Account.RevId__c, (
				SELECT
					Id
				FROM
					OpportunityLineItems), (
				SELECT
					Id,
					Account__c,
					Account_Owner__c,
					Budget__c,
					Product__c,
					Opportunity_Line_Item_Id__c,
					Revenue_Schedule_Date__c
				FROM
					Revenue_Schedules__r
				ORDER BY
					Opportunity_Line_Item_Id__c, Revenue_Schedule_Date__c)
			FROM
				Opportunity
			WHERE
				AccountId IN :accountSet])
		{
			revIdSet.add(opportunity.Account.RevId__c);
			if (oldOwnerMap.containsKey(opportunity.AccountId) &&
				!oldOwnerKeyedOwnerMap.containsKey(opportunity.Account.OwnerId))
			{
				oldOwnerKeyedOwnerMap.put(oldOwnerMap.get(opportunity.AccountId), opportunity.Account.OwnerId);
			}
			for (OpportunityLineItem opportunityLineItem : opportunity.OpportunityLineItems)
			{
				if (!opportunityLineItemRevenueScheduleMap.containsKey(opportunityLineItem.Id))
				{
					opportunityLineItemRevenueScheduleMap.put(opportunityLineItem.Id, new List<Revenue_Schedule__c>());
				}
			}
			for (Revenue_Schedule__c revenueSchedule : opportunity.Revenue_Schedules__r)
			{ 
				if (revenueSchedule.Account_Owner__c != opportunity.Account.OwnerId)
				{
					revenueSchedule.Account_Owner__c = opportunity.Account.OwnerId;
					revenueScheduleCache.add(revenueSchedule);
				}
				System.assertEquals(true, opportunityLineItemRevenueScheduleMap.containsKey((Id)revenueSchedule.Opportunity_Line_Item_Id__c));
				opportunityLineItemRevenueScheduleMap.get((Id)revenueSchedule.Opportunity_Line_Item_Id__c).add(revenueSchedule);
			}
		}
		if (!revenueScheduleCache.isEmpty())
		{
			GSP_SC_ScheduleHelper.LinkBudgets(revenueScheduleCache, opportunityLineItemRevenueScheduleMap, true);
		}
		
		Set<Integer> monthSet = new Set<Integer>(),
			yearSet = new Set<Integer>();
		Map<Id, Map<Integer, Map<Integer, Budget__c>>> budgetSearchMap = new Map<Id, Map<Integer, Map<Integer, Budget__c>>>();
		Set<Id> budgetSet = new Set<Id>();
		
		List<Invoice_Line__c> invoiceLineList = new List<Invoice_Line__c>([
			SELECT
				Id,
				RevId__c,
				Accounting_Period__c,
				Budget__c,
				Budget__r.Account_Owner__c
			FROM
				Invoice_Line__c
			WHERE
				Budget__r.Account_Owner__c IN : oldOwnerKeyedOwnerMap.keySet()
			AND
				RevId__c IN :revIdSet]);
		for (Invoice_Line__c invoiceLine : invoiceLineList)
		{
			monthSet.add(invoiceLine.Accounting_Period__c.month());
			yearSet.add(invoiceLine.Accounting_Period__c.year());
		}
		
		for (Budget__c budget : [
			SELECT
				Id,
				Budget_Date__c,
				Account_Owner__c
			FROM
				Budget__c
			WHERE
				CALENDAR_YEAR(Budget_Date__c) IN :yearSet
			AND
				CALENDAR_MONTH(Budget_Date__c) IN :monthSet
			AND
				Account_Owner__c IN :oldOwnerKeyedOwnerMap.values()])
		{
			if (!budgetSearchMap.containsKey(budget.Account_Owner__c))
			{
				budgetSearchMap.put(budget.Account_Owner__c, new Map<Integer, Map<Integer, Budget__c>>());
			}
			if (!budgetSearchMap.get(budget.Account_Owner__c).containsKey(budget.Budget_Date__c.year()))
			{
				budgetSearchMap.get(budget.Account_Owner__c).put(budget.Budget_Date__c.year(), new Map<Integer, Budget__c>());
			}
			budgetSearchMap.get(budget.Account_Owner__c).get(budget.Budget_Date__c.year()).put(budget.Budget_Date__c.month(), budget);
		}
		
		for (Invoice_Line__c invoiceLine : invoiceLineList)
		{
			if (invoiceLine.Budget__c != null)
			{
				budgetSet.add(invoiceLine.Budget__c);
				invoiceLine.Budget__c = null;
				invoiceLineCacheMap.put(invoiceLine.Id, invoiceLine);
			}
			if (oldOwnerKeyedOwnerMap.containsKey(invoiceLine.Budget__r.Account_Owner__c))
			{
				Id id = oldOwnerKeyedOwnerMap.get(invoiceLine.Budget__r.Account_Owner__c);
				if (budgetSearchMap.containsKey(id))
				{
					if (budgetSearchMap.get(id).containsKey(invoiceLine.Accounting_Period__c.year()))
					{
						if (budgetSearchMap.get(id).get(invoiceLine.Accounting_Period__c.year()).containsKey(invoiceLine.Accounting_Period__c.month()))
						{
							Id budgetId = budgetSearchMap.get(id).get(invoiceLine.Accounting_Period__c.year()).
								get(invoiceLine.Accounting_Period__c.month()).Id;
							invoiceLine.Budget__c = budgetId;
							budgetSet.add(budgetId);
							invoiceLineCacheMap.put(invoiceLine.Id, invoiceLine);
						}
					}
				}
			}
		}
		
		if (!invoiceLineCacheMap.isEmpty())
		{
			update invoiceLineCacheMap.values();
		}
		if (!budgetSet.isEmpty())
		{
			GSP_SC_BudgetHelper.RollUpInvoiceValues(budgetSet);
		}
	}
}