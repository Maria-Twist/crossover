/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, 20 Jul 2020
 */
public with sharing class GSP_SC_trgBudgetMethods
{
	public static void LinkRevenueSchedules(List<Budget__c> budgetList)
	{
		Set<Id> accountSet = new Set<Id>(),
			productSet = new Set<Id>();
		Set<Integer> yearSet = new Set<Integer>(),
			monthSet = new Set<Integer>();
		List<Revenue_Schedule__c> revenueScheduleCache = new List<Revenue_Schedule__c>();
		List<Invoice_Line__c> invoiceLineCache = new List<Invoice_Line__c>();
		Set<Id> budgetSet = new Set<Id>(),
			userSet = new Set<Id>();
		// Map AccountId -> Product -> Year -> Month
		Map<Id, Map<Id, Map<Integer, Map<Integer, Budget__c>>>> budgetSearchMap = new Map<Id, Map<Id, Map<Integer, Map<Integer, Budget__c>>>>();
		// Map Account Owner -> Product -> Year -> Month
		Map<Id, Map<Id, Map<Integer, Map<Integer, Budget__c>>>> budgetUserSearchMap = new Map<Id, Map<Id, Map<Integer, Map<Integer, Budget__c>>>>();
		for (Budget__c budget : budgetlist)
		{
			if (budget.Budget_Date__c != null)
			{
				if (budget.Account__c != null)
				{
					if (!budgetSearchMap.containsKey(budget.Account__c))
					{
						budgetSearchMap.put(budget.Account__c, new Map<Id, Map<Integer, Map<Integer, Budget__c>>>());
					}
					if (!budgetSearchMap.get(budget.Account__c).containsKey(budget.Product__c))
					{
						budgetSearchMap.get(budget.Account__c).put(budget.Product__c, new Map<Integer, Map<Integer, Budget__c>>());
					}
					if (!budgetSearchMap.get(budget.Account__c).get(budget.Product__c).containsKey(budget.Budget_Date__c.year()))
					{
						budgetSearchMap.get(budget.Account__c).get(budget.Product__c).put(budget.Budget_Date__c.year(), new Map<Integer, Budget__c>());
					}
					budgetSearchMap.get(budget.Account__c).get(budget.Product__c).get(budget.Budget_Date__c.year()).
						put(budget.Budget_Date__c.month(), budget);
					budgetSet.add(budget.Id);
					accountSet.add(budget.Account__c);
					yearSet.add(budget.Budget_Date__c.year());
					monthSet.add(budget.Budget_Date__c.month());
					productSet.add(budget.Product__c);
				}
				else if (budget.Account_Owner__c != null)
				{
					if (!budgetUserSearchMap.containsKey(budget.Account_Owner__c))
					{
						budgetUserSearchMap.put(budget.Account_Owner__c, new Map<Id, Map<Integer, Map<Integer, Budget__c>>>());
					}
					if (!budgetUserSearchMap.get(budget.Account_Owner__c).containsKey(budget.Product__c))
					{
						budgetUserSearchMap.get(budget.Account_Owner__c).put(budget.Product__c, new Map<Integer, Map<Integer, Budget__c>>());
					}
					if (!budgetUserSearchMap.get(budget.Account_Owner__c).get(budget.Product__c).containsKey(budget.Budget_Date__c.year()))
					{
						budgetUserSearchMap.get(budget.Account_Owner__c).get(budget.Product__c).
							put(budget.Budget_Date__c.year(), new Map<Integer, Budget__c>());
					}
					budgetUserSearchMap.get(budget.Account_Owner__c).get(budget.Product__c).
						get(budget.Budget_Date__c.year()).put(budget.Budget_Date__c.month(), budget);
					budgetSet.add(budget.Id);	
					userSet.add(budget.Account_Owner__c);
					yearSet.add(budget.Budget_Date__c.year());
					monthSet.add(budget.Budget_Date__c.month());
					productSet.add(budget.Product__c);
				}
			}
		}
		
		for (Revenue_Schedule__c revenueSchedule : [
			SELECT
				Id,
				Budget__c,
				Product__c,
				Revenue_Schedule_Date__c,
				Opportunity__r.AccountId,
				Opportunity__r.Account.OwnerId
			FROM
				Revenue_Schedule__c
			WHERE
				(Opportunity__r.AccountId IN :accountSet
			OR
				Opportunity__r.Account.OwnerId IN :userSet)
			AND
				CALENDAR_MONTH(Revenue_Schedule_Date__c) IN :monthSet
			AND
				CALENDAR_YEAR(Revenue_Schedule_Date__c) IN :yearSet
			AND
				Product__c IN :productSet
			AND
				(Budget__c = null
			OR
				Budget__r.Account__c = null)])
		{
			if (revenueSchedule.Budget__c != null)
			{
				budgetSet.add(revenueSchedule.Budget__c);
				// Don't delete Budget, valid for current Schedule
			}
			Boolean bFound = false;
			if (budgetSearchMap.containsKey(revenueSchedule.Opportunity__r.AccountId))
			{
				if (budgetSearchMap.get(revenueSchedule.Opportunity__r.AccountId).containsKey(revenueSchedule.Product__c))
				{
					if (budgetSearchMap.get(revenueSchedule.Opportunity__r.AccountId).get(revenueSchedule.Product__c).
						containsKey(revenueSchedule.Revenue_Schedule_Date__c.year()))
					{
						if (budgetSearchMap.get(revenueSchedule.Opportunity__r.AccountId).get(revenueSchedule.Product__c).
							get(revenueSchedule.Revenue_Schedule_Date__c.year()).containsKey(revenueSchedule.Revenue_Schedule_Date__c.month()))
						{
							Id budgetId = budgetSearchMap.get(revenueSchedule.Opportunity__r.AccountId).get(revenueSchedule.Product__c).
								get(revenueSchedule.Revenue_Schedule_Date__c.year()).get(revenueSchedule.Revenue_Schedule_Date__c.month()).Id;
							if (revenueSchedule.Budget__c != budgetId)
							{
								budgetSet.add(revenueSchedule.Budget__c);
								revenueSchedule.Budget__c = budgetId;
								revenueScheduleCache.add(revenueSchedule);
							}
							bFound = true;
						}
					}
				}
			}
			if (!bFound)
			{
				if (budgetUserSearchMap.containsKey(revenueSchedule.Opportunity__r.Account.OwnerId))
				{
					if (budgetUserSearchMap.get(revenueSchedule.Opportunity__r.Account.OwnerId).containsKey(revenueSchedule.Product__c))
					{
						if (budgetUserSearchMap.get(revenueSchedule.Opportunity__r.Account.OwnerId).get(revenueSchedule.Product__c).
							containsKey(revenueSchedule.Revenue_Schedule_Date__c.year()))
						{
							if (budgetUserSearchMap.get(revenueSchedule.Opportunity__r.Account.OwnerId).get(revenueSchedule.Product__c).
								get(revenueSchedule.Revenue_Schedule_Date__c.year()).containsKey(revenueSchedule.Revenue_Schedule_Date__c.month()))
							{
								Id budgetId = budgetUserSearchMap.get(revenueSchedule.Opportunity__r.Account.OwnerId).get(revenueSchedule.Product__c).
									get(revenueSchedule.Revenue_Schedule_Date__c.year()).get(revenueSchedule.Revenue_Schedule_Date__c.month()).Id;
								if (revenueSchedule.Budget__c != budgetId)
								{
									budgetSet.add(revenueSchedule.Budget__c);
									revenueSchedule.Budget__c = budgetId;
									revenueScheduleCache.add(revenueSchedule);
								}
								bFound = true;
							}
						}
					}
				}
			}
		}
		
		if (!revenueScheduleCache.isEmpty())
		{
			update revenueScheduleCache;
		}
		
		if (!budgetSet.isEmpty())
		{
			GSP_SC_BudgetHelper.RollUpScheduleValues(budgetSet);
		}

		for (Account account : [
			SELECT
				Id,
				OwnerId,
				RevId__c, (
				SELECT
					Id,
					Account__c,
					Account__r.OwnerId,
					Budget__c,
					Product__c,
					RevId__c,
					Accounting_Period__c
				FROM
					Invoice_Lines__r
				WHERE
					CALENDAR_YEAR(Accounting_Period__c) IN :yearSet
				AND
					CALENDAR_MONTH(Accounting_Period__c) IN :monthSet
				AND
					Product__c IN :productSet
				AND
					(Budget__c = null
				OR
					Budget__r.Account__c = null))
			FROM
				Account
			WHERE
				Id IN :accountSet
			OR
				OwnerId IN :userSet])
		{
			for (Invoice_Line__c invoiceLine : account.Invoice_Lines__r)
			{
				Boolean bFound = false;
				if (budgetSearchMap.containsKey(invoiceLine.Account__c))
				{
					if (budgetSearchMap.get(invoiceLine.Account__c).containsKey(invoiceLine.Product__c))
					{
						if (budgetSearchMap.get(invoiceLine.Account__c).get(invoiceLine.Product__c).
							containsKey(invoiceLine.Accounting_Period__c.year()))
						{
							if (budgetSearchMap.get(invoiceLine.Account__c).get(invoiceLine.Product__c).
								get(invoiceLine.Accounting_Period__c.year()).containsKey(invoiceLine.Accounting_Period__c.month()))
							{
								Id budgetId = budgetSearchMap.get(invoiceLine.Account__c).get(invoiceLine.Product__c).
									get(invoiceLine.Accounting_Period__c.year()).get(invoiceLine.Accounting_Period__c.month()).Id;
								if (invoiceLine.Budget__c != budgetId)
								{
									budgetSet.add(invoiceLine.Budget__c);
									invoiceLine.Budget__c = budgetId;
									invoiceLineCache.add(invoiceLine);
								}
								bFound = true;
							}
						}
					}
				}
				if (!bFound)
				{
					if (budgetUserSearchMap.containsKey(invoiceLine.Account__r.OwnerId))
					{
						if (budgetUserSearchMap.get(invoiceLine.Account__r.OwnerId).containsKey(invoiceLine.Product__c))
						{
							if (budgetUserSearchMap.get(invoiceLine.Account__r.OwnerId).get(invoiceLine.Product__c).
								containsKey(invoiceLine.Accounting_Period__c.year()))
							{
								if (budgetUserSearchMap.get(invoiceLine.Account__r.OwnerId).get(invoiceLine.Product__c).
									get(invoiceLine.Accounting_Period__c.year()).containsKey(invoiceLine.Accounting_Period__c.month()))
								{
									Id budgetId = budgetUserSearchMap.get(invoiceLine.Account__r.OwnerId).get(invoiceLine.Product__c).
										get(invoiceLine.Accounting_Period__c.year()).get(invoiceLine.Accounting_Period__c.month()).Id;
									if (invoiceLine.Budget__c != budgetId)
									{
										budgetSet.add(invoiceLine.Budget__c);
										invoiceLine.Budget__c = budgetId;
										invoiceLineCache.add(invoiceLine);
									}
									bFound = true;
								}
							}
						}
					}
				}
			}
		}
		
		if (!invoiceLineCache.isEmpty())
		{
			update invoiceLineCache;
		}
		if (!budgetSet.isEmpty())
		{
			GSP_SC_BudgetHelper.RollUpInvoiceValues(budgetSet);
		}
	}
	
	public static void SetOwner(List<Budget__c> budgetList)
	{
		Map<Id, List<Budget__c>> accountKeyedBudgetMap = new Map<Id, List<Budget__c>>();
		for (Budget__c budget : budgetList)
		{
			if (budget.Account__c != null)
			{
				if (!accountKeyedBudgetMap.containsKey(budget.Account__c))
				{
					accountKeyedBudgetMap.put(budget.Account__c, new List<Budget__c>());
				}
				accountKeyedBudgetMap.get(budget.Account__c).add(budget);
			}
			else
			{
				budget.OwnerId = budget.Account_Owner__c;
			}
		}
		
		for (Account account : [
			SELECT
				Id,
				OwnerId
			FROM
				Account
			WHERE
				Id IN :accountKeyedBudgetMap.keySet()])
		{
			if (accountKeyedBudgetMap.containsKey(account.Id))
			{
				for (Budget__c budget : accountKeyedBudgetMap.get(account.Id))
				{
					budget.OwnerId = account.OwnerId;
				}
			}
		}
	}
	
	public static void LinkBudgets(List<Budget__c> budgetList)
	{
		Set<String> accountNameSet = new Set<String>();
		Set<String> productCodeNameSet = new Set<String>();
		Set<Integer> monthSet = new Set<Integer>();
		Set<Integer> yearSet = new Set<Integer>();
		Map<String, Product2> codeKeyedProductMap = new Map<String, Product2>();
		Map<String, Account> nameKeyedAccountMap = new Map<String, Account>();
		
		for (Budget__c budget : budgetList)
		{
			System.assertNotEquals(null, budget.Budget_Date__c);
			monthSet.add(budget.Budget_Date__c.month());
			yearSet.add(budget.Budget_Date__c.year());
			if (!String.isEmpty(budget.Account_Name__c))
			{
				accountNameSet.add(budget.Account_Name__c);
			}
			if (!String.isEmpty(budget.Product_Code_Name__c))
			{
				productCodeNameSet.add(budget.Product_Code_Name__c);
			}
		}
		
		if (!productCodeNameSet.isEmpty())
		{
			for (Product2 product : [
				SELECT
					Id,
					ProductCode
				FROM
					Product2
				WHERE
					ProductCode IN :productCodeNameSet])
			{
				if (codeKeyedProductMap.containsKey(product.ProductCode))
				{
					System.assert(false, 'Product Code \'' + product.ProductCode + '\' exists in multiple Products.');
				}
				codeKeyedProductMap.put(product.ProductCode, product);
			}
		}
		
		if (!accountNameSet.isEmpty())
		{
			for (Account account : [
				SELECT
					Id,
					Name
				FROM
					Account
				WHERE
					Name IN :accountNameSet])
			{
				if (nameKeyedAccountMap.containskey(account.Name))
				{
					System.assert(false, 'Multiple Accounts with the Name \'' + account.Name + '\' exists.');
				}
				nameKeyedAccountMap.put(account.Name, account);
			}
		}
		
		for (Budget__c budget : budgetList)
		{
			if (!String.isEmpty(budget.Product_Code_Name__c))
			{
				if (!codeKeyedProductMap.isEmpty() && codeKeyedProductMap.containsKey(budget.Product_Code_Name__c))
				{
					budget.Product__c = codeKeyedProductMap.get(budget.Product_Code_Name__c).Id;
				}
				System.assertNotEquals(null, budget.Product__c, 'Unable to locate Product with Product Code of \'' + budget.Product_Code_Name__c + '\'.');
			}
			
			if (!String.isEmpty(budget.Account_Name__c))
			{
				if (!nameKeyedAccountMap.isEmpty() && nameKeyedAccountMap.containsKey(budget.Account_Name__c))
				{
					budget.Account__c = nameKeyedAccountMap.get(budget.Account_Name__c).Id;
				}
				System.assertNotEquals(null, budget.Account__c, 'Unable to locate Account with name of \'' + budget.Account_Name__c + '\'.');
			}
		}
	}
}