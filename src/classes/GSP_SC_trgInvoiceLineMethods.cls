/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, 22 Jul 2020
 */
public with sharing class GSP_SC_trgInvoiceLineMethods
{
	public static void LinkInvoicelineBudgets(Set<Id> invoiceLineSet)
	{
		Set<String> revIdSet = new Set<String>(),
			clinicNameSet = new Set<String>();
		Set<Integer> monthSet = new Set<Integer>(),
			yearSet = new Set<Integer>();
		Set<Id> accountOwnerSet = new Set<Id>(),
			budgetSet = new Set<Id>(),
			productSet = new Set<Id>(),
			clinicBudgetSet = new Set<Id>();
		List<Invoice_Line__c> invoiceLinesNotMatchedByAccount = new List<Invoice_Line__c>();
		Map<Id, Invoice_Line__c> invoiceLineCacheMap = new Map<Id, Invoice_Line__c>();
		Map<String, Id> revIdKeyedAccountOwnerSet = new Map<String, Id>();
		Map<String, Id> revIdKeyedAccountSet = new Map<String, Id>();
		// Map RevId -> Product -> Budget Year - Budget-Month
		Map<String, Map<Id, Map<Integer, Map<Integer, Budget__c>>>> budgetSearchMap = new Map<String, Map<Id, Map<Integer, Map<Integer, Budget__c>>>>();
		// Map Account Owner -> Product -> Budget Year - Budget-Month
		Map<Id, Map<Id, Map<Integer, Map<Integer, Budget__c>>>> budgetOwnerSearchMap = new Map<Id, Map<Id, Map<Integer, Map<Integer, Budget__c>>>>();
		// Map -> Clinic Name -> Year -> Month
		Map<String, Map<Integer, Map<Integer, Clinic_Budget__c>>> clinicBudgetSearchMap = new Map<String, Map<Integer, Map<Integer, Clinic_Budget__c>>>();
		
		List<Invoice_Line__c> invoiceLineList = new List<Invoice_Line__c>([
			SELECT
				Id,
				RevId__c,
				Accounting_Period__c,
				Budget__c,
				Clinic__c,
				Product__c
			FROM
				Invoice_Line__c
			WHERE
				Id IN :invoiceLineSet]);
		
		for (Invoice_Line__c invoiceLine : invoiceLineList)
		{
			if (!String.isEmpty(invoiceLine.RevId__c) &&
				invoiceLine.Accounting_Period__c != null &&
				invoiceLine.Product__c != null)
			{
				revIdSet.add(invoiceLine.RevId__c);
				monthSet.add(invoiceLine.Accounting_Period__c.month());
				yearSet.add(invoiceLine.Accounting_Period__c.year());
				productSet.add(invoiceLine.Product__c);
				if (invoiceLine.Clinic__c != null)
				{
					clinicNameSet.add(invoiceLine.Clinic__c);
				}
			}
			else
			{
				invoiceLine.addError('No Account RevId, Accounting Period or Product to process.');
				return;
			}
		}
		
		for (Account account : [
			SELECT
				Id,
				OwnerId,
				RevId__c, (
				SELECT
					Id,
					Budget_Date__c,
					Product__c
				FROM
					Budgets__r
				WHERE
					CALENDAR_YEAR(Budget_Date__c) IN :yearSet
				AND
					CALENDAR_MONTH(Budget_Date__c) IN :monthSet
				AND
					Product__c IN :productSet)
			FROM
				Account
			WHERE
				RevId__c IN :revIdSet])
		{
			revIdKeyedAccountOwnerSet.put(account.RevId__c, account.OwnerId);
			revIdKeyedAccountSet.put(account.RevId__c, account.Id);
			if (!budgetSearchMap.containsKey(account.RevId__c))
			{
				budgetSearchMap.put(account.RevId__c, new Map<Id, Map<Integer, Map<Integer, Budget__c>>>());
			}
			for (Budget__c budget : account.Budgets__r)
			{
				if (!budgetSearchMap.get(account.RevId__c).containsKey(budget.Product__c))
				{
					budgetSearchMap.get(account.RevId__c).put(budget.Product__c, new Map<Integer, Map<Integer, Budget__c>>());
				}
				if (!budgetSearchMap.get(account.RevId__c).get(budget.Product__c).containsKey(budget.Budget_Date__c.year()))
				{
					budgetSearchMap.get(account.RevId__c).get(budget.Product__c).put(budget.Budget_Date__c.year(), new Map<Integer, Budget__c>());
				}
				budgetSearchMap.get(account.RevId__c).get(budget.Product__c).get(budget.Budget_Date__c.year()).put(budget.Budget_Date__c.month(), budget);
			}	
		}
		
		for (Clinic_Budget__c clinicBudget : [
			SELECT
				Id,
				Budget_Date__c,
				Clinic_Name__c
			FROM
				Clinic_Budget__c
			WHERE
				CALENDAR_YEAR(Budget_Date__c) IN :yearSet
			AND
				CALENDAR_MONTH(Budget_Date__c) IN :monthSet
			AND
				Clinic_name__c IN :clinicNameSet])
		{
			if (!clinicBudgetSearchMap.containsKey(clinicBudget.Clinic_Name__c))
			{
				clinicBudgetSearchMap.put(clinicBudget.Clinic_Name__c, new Map<Integer, Map<Integer, Clinic_Budget__c>>());
			}
			if (!clinicBudgetSearchMap.get(clinicBudget.Clinic_Name__c).containsKey(clinicBudget.Budget_Date__c.year()))
			{
				clinicBudgetSearchMap.get(clinicBudget.Clinic_Name__c).put(clinicBudget.Budget_Date__c.year(), new Map<Integer, Clinic_Budget__c>());
			}
			clinicBudgetSearchMap.get(clinicBudget.Clinic_Name__c).get(clinicBudget.Budget_Date__c.year()).put(clinicBudget.Budget_Date__c.month(), clinicBudget);
		}
		
		monthSet.clear();
		yearSet.clear();
		productSet.clear();
		// Added debug statements for inevitable typos.
		for (Invoice_Line__c invoiceLine : invoiceLineList)
		{
			invoiceLine.Account__c = revIdKeyedAccountSet.get(invoiceLine.RevId__c);
			invoiceLineCacheMap.put(invoiceLine.Id, invoiceLine);
			if (invoiceLine.Budget__c != null)
			{
				budgetSet.add(invoiceLine.Budget__c);
			}
			Boolean bFound = false;
			System.debug('Match Account');
			if (budgetSearchMap.containsKey(invoiceLine.RevId__c))
			{System.debug('MA Key 1');
				if (budgetSearchMap.get(invoiceLine.RevId__c).containsKey(invoiceLine.Product__c))
				{System.debug('MA Key 2');
					if (budgetSearchMap.get(invoiceLine.RevId__c).get(invoiceLine.Product__c).
						containsKey(invoiceLine.Accounting_Period__c.year()))
					{System.debug('MA Key 3');
						if (budgetSearchMap.get(invoiceLine.RevId__c).get(invoiceLine.Product__c).
							get(invoiceLine.Accounting_Period__c.year()).containsKey(invoiceLine.Accounting_Period__c.month()))
						{System.debug('MA Key 4');
							Id budgetId = budgetSearchMap.get(invoiceLine.RevId__c).get(invoiceLine.Product__c).
								get(invoiceLine.Accounting_Period__c.year()).get(invoiceLine.Accounting_Period__c.month()).Id;
							invoiceLine.Budget__c = budgetId;
							budgetSet.add(invoiceLine.Budget__c);
							bFound = true;
						}
					}
				}
			}
			if (!bFound)
			{
				invoiceLinesNotMatchedByAccount.add(invoiceLine);
				if (revIdKeyedAccountOwnerSet.get(invoiceLine.RevId__c) != null)
				{
					accountOwnerSet.add(revIdKeyedAccountOwnerSet.get(invoiceLine.RevId__c));
					monthSet.add(invoiceLine.Accounting_Period__c.month());
					yearSet.add(invoiceLine.Accounting_Period__c.year());
					productSet.add(invoiceLine.Product__c);
				}
			}
			
			if (invoiceLine.Clinic__c != null)
			{
				if (clinicBudgetSearchMap.containsKey(invoiceLine.Clinic__c))
				{
					if (clinicBudgetSearchMap.get(invoiceLine.Clinic__c).containsKey(invoiceLine.Accounting_Period__c.year()))
					{System.debug('INV: ' + invoiceLine + ' - ' + clinicBudgetSearchMap.get(invoiceLine.Clinic__c).get(invoiceLine.Accounting_Period__c.year()));
						if (clinicBudgetSearchMap.get(invoiceLine.Clinic__c).get(invoiceLine.Accounting_Period__c.year()).
							containsKey(invoiceLine.Accounting_Period__c.month()))
						{
							Id clinicBudgetId = clinicBudgetSearchMap.get(invoiceLine.Clinic__c).get(invoiceLine.Accounting_Period__c.year()).
								get(invoiceLine.Accounting_Period__c.month()).Id;
							invoiceLine.Clinic_Budget__c = clinicBudgetId;
							clinicBudgetSet.add(clinicBudgetId);
						}
					}
				}
			}
		}
		
		if (!accountOwnerSet.isEmpty())
		{
			for (Budget__c budget : [
				SELECT
					Id,
					Name,
					Account_Owner__c,
					Budget_Date__c,
					Product__c
				FROM
					Budget__c
				WHERE
					Account_Owner__c IN :accountOwnerSet
				AND
					CALENDAR_YEAR(Budget_Date__c) IN :yearSet
				AND
					CALENDAR_MONTH(Budget_Date__c) IN :monthSet
				AND
					Product__c IN :productSet
				AND
					Account_Owner__c != null])
			{
				System.debug(budget.Name + ' : ' + budget.Account_Owner__c);
				if (!budgetOwnerSearchMap.containsKey(budget.Account_Owner__c))
				{
					budgetOwnerSearchMap.put(budget.Account_Owner__c, new Map<Id, Map<Integer, Map<Integer, Budget__c>>>());
				}
				if (!budgetOwnerSearchMap.get(budget.Account_Owner__c).containsKey(budget.Product__c))
				{
					budgetOwnerSearchMap.get(budget.Account_Owner__c).put(budget.Product__c, new Map<Integer, Map<Integer, Budget__c>>());
				}
				if (!budgetOwnerSearchMap.get(budget.Account_Owner__c).get(budget.Product__c).
					containsKey(budget.Budget_Date__c.year()))
				{
					budgetOwnerSearchMap.get(budget.Account_Owner__c).get(budget.Product__c).
						put(budget.Budget_Date__c.year(), new Map<Integer, Budget__c>());
				}
				budgetOwnerSearchMap.get(budget.Account_Owner__c).get(budget.Product__c).
					get(budget.Budget_Date__c.year()).put(budget.Budget_Date__c.month(), budget);
			}
			
			for (Invoice_Line__c invoiceLine : invoiceLinesNotMatchedByAccount)
			{
				Boolean bFound = false;
				System.debug('Match Owner');
				if (budgetOwnerSearchMap.containsKey(revIdKeyedAccountOwnerSet.get(invoiceLine.RevId__c)))
				{System.debug('MO Key 1');
					if (budgetOwnerSearchMap.get(revIdKeyedAccountOwnerSet.get(invoiceLine.RevId__c)).containsKey(invoiceLine.Product__c))
					{System.debug('MO Key 2');
						if (budgetOwnerSearchMap.get(revIdKeyedAccountOwnerSet.get(invoiceLine.RevId__c)).get(invoiceLine.Product__c).
							containsKey(invoiceLine.Accounting_Period__c.year()))
						{System.debug('MO Key 3');
							if (budgetOwnerSearchMap.get(revIdKeyedAccountOwnerSet.get(invoiceLine.RevId__c)).get(invoiceLine.Product__c).
								get(invoiceLine.Accounting_Period__c.year()).containsKey(invoiceLine.Accounting_Period__c.month()))
							{System.debug('MO Key 4');
								Id budgetId = budgetOwnerSearchMap.get(revIdKeyedAccountOwnerSet.get(invoiceLine.RevId__c)).get(invoiceLine.Product__c).
									get(invoiceLine.Accounting_Period__c.year()).get(invoiceLine.Accounting_Period__c.month()).Id;
								invoiceLine.Budget__c = budgetId;
								budgetSet.add(invoiceLine.Budget__c);
								invoiceLineCacheMap.put(invoiceLine.Id, invoiceLine);
								bFound = true;
							}
						}
					}
				}
				if (!bFound)
				{
					
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
		if (!clinicBudgetSet.isEmpty())
		{
			GSP_SC_ClinicBudgetHelper.RollUpClinicBudgets(clinicBudgetSet);
		}
	}
	
	public static void LinkInvoicelineBudgetsByAccountName(Set<Id> invoiceLineSet)
	{
		Set<String> accountNameSet = new Set<String>(),
			clinicNameSet = new Set<String>();
		Set<Integer> monthSet = new Set<Integer>(),
			yearSet = new Set<Integer>();
		Set<Id> accountOwnerSet = new Set<Id>(),
			budgetSet = new Set<Id>(),
			productSet = new Set<Id>(),
			clinicBudgetSet = new Set<Id>();
		List<Invoice_Line__c> invoiceLinesNotMatchedByAccount = new List<Invoice_Line__c>();
		Map<Id, Invoice_Line__c> invoiceLineCacheMap = new Map<Id, Invoice_Line__c>();
		Map<String, Id> revIdKeyedAccountOwnerSet = new Map<String, Id>();
		Map<String, Id> revIdKeyedAccountSet = new Map<String, Id>();
		// Map RevId -> Product -> Budget Year - Budget-Month
		Map<String, Map<Id, Map<Integer, Map<Integer, Budget__c>>>> budgetSearchMap = new Map<String, Map<Id, Map<Integer, Map<Integer, Budget__c>>>>();
		// Map Account Owner -> Product -> Budget Year - Budget-Month
		Map<Id, Map<Id, Map<Integer, Map<Integer, Budget__c>>>> budgetOwnerSearchMap = new Map<Id, Map<Id, Map<Integer, Map<Integer, Budget__c>>>>();
		// Map -> Clinic Name -> Year -> Month
		Map<String, Map<Integer, Map<Integer, Clinic_Budget__c>>> clinicBudgetSearchMap = new Map<String, Map<Integer, Map<Integer, Clinic_Budget__c>>>();
		
		List<Invoice_Line__c> invoiceLineList = new List<Invoice_Line__c>([
			SELECT
				Id,
				Account_Name__c,
				Accounting_Period__c,
				Budget__c,
				Product__c,
				Clinic__c
			FROM
				Invoice_Line__c
			WHERE
				Id IN :invoiceLineSet]);
		
		for (Invoice_Line__c invoiceLine : invoiceLineList)
		{
			if (!String.isEmpty(invoiceLine.Account_Name__c) &&
				invoiceLine.Accounting_Period__c != null &&
				invoiceLine.Product__c != null)
			{
				accountNameSet.add(invoiceLine.Account_Name__c);
				monthSet.add(invoiceLine.Accounting_Period__c.month());
				yearSet.add(invoiceLine.Accounting_Period__c.year());
				productSet.add(invoiceLine.Product__c);
				if (invoiceLine.Clinic__c != null)
				{
					clinicNameSet.add(invoiceLine.Clinic__c);
				}
			}
			else
			{
				invoiceLine.addError('No Account Name, Accounting Period or Product to process.');
				return;
			}
		}
		
		for (Account account : [
			SELECT
				Id,
				OwnerId,
				Name, (
				SELECT
					Id,
					Budget_Date__c,
					Product__c
				FROM
					Budgets__r
				WHERE
					CALENDAR_YEAR(Budget_Date__c) IN :yearSet
				AND
					CALENDAR_MONTH(Budget_Date__c) IN :monthSet
				AND
					Product__c IN :productSet)
			FROM
				Account
			WHERE
				Name IN :accountNameSet])
		{
			revIdKeyedAccountOwnerSet.put(account.Name, account.OwnerId);
			revIdKeyedAccountSet.put(account.Name, account.Id);
			if (!budgetSearchMap.containsKey(account.Name))
			{
				budgetSearchMap.put(account.Name, new Map<Id, Map<Integer, Map<Integer, Budget__c>>>());
			}
			for (Budget__c budget : account.Budgets__r)
			{
				if (!budgetSearchMap.get(account.Name).containsKey(budget.Product__c))
				{
					budgetSearchMap.get(account.Name).put(budget.Product__c, new Map<Integer, Map<Integer, Budget__c>>());
				}
				if (!budgetSearchMap.get(account.Name).get(budget.Product__c).containsKey(budget.Budget_Date__c.year()))
				{
					budgetSearchMap.get(account.Name).get(budget.Product__c).put(budget.Budget_Date__c.year(), new Map<Integer, Budget__c>());
				}
				budgetSearchMap.get(account.Name).get(budget.Product__c).get(budget.Budget_Date__c.year()).put(budget.Budget_Date__c.month(), budget);
			}	
		}
		
		for (Clinic_Budget__c clinicBudget : [
			SELECT
				Id,
				Budget_Date__c,
				Clinic_Name__c
			FROM
				Clinic_Budget__c
			WHERE
				CALENDAR_YEAR(Budget_Date__c) IN :yearSet
			AND
				CALENDAR_MONTH(Budget_Date__c) IN :monthSet
			AND
				Clinic_name__c IN :clinicNameSet])
		{
			if (!clinicBudgetSearchMap.containsKey(clinicBudget.Clinic_Name__c))
			{
				clinicBudgetSearchMap.put(clinicBudget.Clinic_Name__c, new Map<Integer, Map<Integer, Clinic_Budget__c>>());
			}
			if (!clinicBudgetSearchMap.get(clinicBudget.Clinic_Name__c).containsKey(clinicBudget.Budget_Date__c.year()))
			{
				clinicBudgetSearchMap.get(clinicBudget.Clinic_Name__c).put(clinicBudget.Budget_Date__c.year(), new Map<Integer, Clinic_Budget__c>());
			}
			clinicBudgetSearchMap.get(clinicBudget.Clinic_Name__c).get(clinicBudget.Budget_Date__c.year()).put(clinicBudget.Budget_Date__c.month(), clinicBudget);
		}
		
		monthSet.clear();
		yearSet.clear();
		productSet.clear();
		// Added debug statements for inevitable typos.
		for (Invoice_Line__c invoiceLine : invoiceLineList)
		{
			invoiceLine.Account__c = revIdKeyedAccountSet.get(invoiceLine.Account_Name__c);
			invoiceLineCacheMap.put(invoiceLine.Id, invoiceLine);
			if (invoiceLine.Budget__c != null)
			{
				budgetSet.add(invoiceLine.Budget__c);
			}
			Boolean bFound = false;
			System.debug('Match Account');
			if (budgetSearchMap.containsKey(invoiceLine.Account_Name__c))
			{System.debug('MA Key 1');
				if (budgetSearchMap.get(invoiceLine.Account_Name__c).containsKey(invoiceLine.Product__c))
				{System.debug('MA Key 2');
					if (budgetSearchMap.get(invoiceLine.Account_Name__c).get(invoiceLine.Product__c).
						containsKey(invoiceLine.Accounting_Period__c.year()))
					{System.debug('MA Key 3');
						if (budgetSearchMap.get(invoiceLine.Account_Name__c).get(invoiceLine.Product__c).
							get(invoiceLine.Accounting_Period__c.year()).containsKey(invoiceLine.Accounting_Period__c.month()))
						{System.debug('MA Key 4');
							Id budgetId = budgetSearchMap.get(invoiceLine.Account_Name__c).get(invoiceLine.Product__c).
								get(invoiceLine.Accounting_Period__c.year()).get(invoiceLine.Accounting_Period__c.month()).Id;
							invoiceLine.Budget__c = budgetId;
							budgetSet.add(invoiceLine.Budget__c);
							bFound = true;
						}
					}
				}
			}
			if (!bFound)
			{
				invoiceLinesNotMatchedByAccount.add(invoiceLine);
				if (revIdKeyedAccountOwnerSet.get(invoiceLine.Account_Name__c) != null)
				{
					accountOwnerSet.add(revIdKeyedAccountOwnerSet.get(invoiceLine.Account_Name__c));
					monthSet.add(invoiceLine.Accounting_Period__c.month());
					yearSet.add(invoiceLine.Accounting_Period__c.year());
					productSet.add(invoiceLine.Product__c);
				}
			}
			if (invoiceLine.Clinic__c != null)
			{
				if (clinicBudgetSearchMap.containsKey(invoiceLine.Clinic__c))
				{
					if (clinicBudgetSearchMap.get(invoiceLine.Clinic__c).containsKey(invoiceLine.Accounting_Period__c.year()))
					{
						if (clinicBudgetSearchMap.get(invoiceLine.Clinic__c).get(invoiceLine.Accounting_Period__c.year()).
							containsKey(invoiceLine.Accounting_Period__c.month()))
						{
							Id clinicBudgetId = clinicBudgetSearchMap.get(invoiceLine.Clinic__c).get(invoiceLine.Accounting_Period__c.year()).
								get(invoiceLine.Accounting_Period__c.month()).Id;
							invoiceLine.Clinic_Budget__c = clinicBudgetId;
							clinicBudgetSet.add(clinicBudgetId);
						}
					}
				}
			}
		}
		
		if (!accountOwnerSet.isEmpty())
		{
			for (Budget__c budget : [
				SELECT
					Id,
					Name,
					Account_Owner__c,
					Budget_Date__c,
					Product__c
				FROM
					Budget__c
				WHERE
					Account_Owner__c IN :accountOwnerSet
				AND
					CALENDAR_YEAR(Budget_Date__c) IN :yearSet
				AND
					CALENDAR_MONTH(Budget_Date__c) IN :monthSet
				AND
					Product__c IN :productSet
				AND
					Account_Owner__c != null])
			{
				System.debug(budget.Name + ' : ' + budget.Account_Owner__c);
				if (!budgetOwnerSearchMap.containsKey(budget.Account_Owner__c))
				{
					budgetOwnerSearchMap.put(budget.Account_Owner__c, new Map<Id, Map<Integer, Map<Integer, Budget__c>>>());
				}
				if (!budgetOwnerSearchMap.get(budget.Account_Owner__c).containsKey(budget.Product__c))
				{
					budgetOwnerSearchMap.get(budget.Account_Owner__c).put(budget.Product__c, new Map<Integer, Map<Integer, Budget__c>>());
				}
				if (!budgetOwnerSearchMap.get(budget.Account_Owner__c).get(budget.Product__c).
					containsKey(budget.Budget_Date__c.year()))
				{
					budgetOwnerSearchMap.get(budget.Account_Owner__c).get(budget.Product__c).
						put(budget.Budget_Date__c.year(), new Map<Integer, Budget__c>());
				}
				budgetOwnerSearchMap.get(budget.Account_Owner__c).get(budget.Product__c).
					get(budget.Budget_Date__c.year()).put(budget.Budget_Date__c.month(), budget);
			}
			
			for (Invoice_Line__c invoiceLine : invoiceLinesNotMatchedByAccount)
			{
				Boolean bFound = false;
				System.debug('Match Owner');
				if (budgetOwnerSearchMap.containsKey(revIdKeyedAccountOwnerSet.get(invoiceLine.Account_Name__c)))
				{System.debug('MO Key 1');
					if (budgetOwnerSearchMap.get(revIdKeyedAccountOwnerSet.get(invoiceLine.Account_Name__c)).containsKey(invoiceLine.Product__c))
					{System.debug('MO Key 2');
						if (budgetOwnerSearchMap.get(revIdKeyedAccountOwnerSet.get(invoiceLine.Account_Name__c)).get(invoiceLine.Product__c).
							containsKey(invoiceLine.Accounting_Period__c.year()))
						{System.debug('MO Key 3');
							if (budgetOwnerSearchMap.get(revIdKeyedAccountOwnerSet.get(invoiceLine.Account_Name__c)).get(invoiceLine.Product__c).
								get(invoiceLine.Accounting_Period__c.year()).containsKey(invoiceLine.Accounting_Period__c.month()))
							{System.debug('MO Key 4');
								Id budgetId = budgetOwnerSearchMap.get(revIdKeyedAccountOwnerSet.get(invoiceLine.Account_Name__c)).get(invoiceLine.Product__c).
									get(invoiceLine.Accounting_Period__c.year()).get(invoiceLine.Accounting_Period__c.month()).Id;
								invoiceLine.Budget__c = budgetId;
								budgetSet.add(invoiceLine.Budget__c);
								invoiceLineCacheMap.put(invoiceLine.Id, invoiceLine);
								bFound = true;
							}
						}
					}
				}
				if (!bFound)
				{
					
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
		if (!clinicBudgetSet.isEmpty())
		{
			GSP_SC_ClinicBudgetHelper.RollUpClinicBudgets(clinicBudgetSet);
		}
	}
	
	public static void RollUpBudgets(List<Invoice_Line__c> invoiceLineList)
	{
		Set<Id> budgetSet = new Set<Id>();
		Set<Id> clinicBudgetSet = new Set<Id>();
		for (Invoice_Line__c invoiceLine : invoiceLineList)
		{
			if (invoiceLine.Budget__c != null)
			{
				budgetSet.add(invoiceLine.Budget__c);
			}
			if (invoiceLine.Clinic_Budget__c != null)
			{
				clinicBudgetSet.add(invoiceLine.Clinic_Budget__c);
			}
		}
		if (!budgetSet.isEmpty())
		{
			GSP_SC_BudgetHelper.RollUpInvoiceValues(budgetSet);
		}
		if (!clinicBudgetSet.isEmpty())
		{
			GSP_SC_ClinicBudgetHelper.RollUpClinicBudgets(clinicBudgetSet);
		}
	}
	
	public static void LinkInvoiceLineProducts(List<Invoice_Line__c> invoiceLineList)
	{
		Map<String, List<Invoice_Line__c>> productCodeKeyedInvoiceMap = new Map<String, List<Invoice_Line__c>>();
		Set<String> productCodeSet = new Set<String>();
		for (Invoice_Line__c invoiceLine : invoiceLineList)
		{
			if (invoiceLine.Salesforce_Product__c != null)
			{
				if (!productCodeKeyedInvoiceMap.containsKey(invoiceLine.Salesforce_Product__c))
				{
					productCodeKeyedInvoiceMap.put(invoiceLine.Salesforce_Product__c, new List<Invoice_Line__c>());
				}
				productCodeKeyedInvoiceMap.get(invoiceLine.Salesforce_Product__c).add(invoiceLine);
			}
		}
		
		for (Product2 product : [
			SELECT
				Id,
				ProductCode
			FROM
				Product2
			WHERE
				ProductCode IN :productCodeKeyedInvoiceMap.keySet()])
		{
			productCodeSet.add(product.ProductCode);
			for (Invoice_Line__c invoiceLine : productCodeKeyedInvoiceMap.get(product.ProductCode))
			{
				invoiceLine.Product__c = product.Id;
			}
		}
		
		for (String strKey : productCodeKeyedInvoiceMap.keySet())
		{
			if (!productCodeSet.contains(strKey))
			{
				System.debug('Product search on InvoiceLine failed for ' + strKey);
			}
		}
	}
}