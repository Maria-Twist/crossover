/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, 20 Jul 2020
 */
public with sharing class GSP_SC_trgClinicBudgetMethods
{
	public static void LinkLineItemsAndSchedules(List<Clinic_Budget__c> clinicBudgetList)
	{
		Set<Integer> monthSet = new Set<Integer>(),
			yearSet = new Set<Integer>();
		Set<String> clinicNameSet = new Set<String>();
		Set<Id> clinicBudgetSet = new Set<Id>();
		Map<String, Map<Integer, Map<Integer, Clinic_Budget__c>>> clinicBudgetSearchMap = new Map<String, Map<Integer, Map<Integer, Clinic_Budget__c>>>();
		List<Invoice_Line__c> invoiceLineCache = new List<Invoice_Line__c>();
		List<Revenue_Schedule__c> revenueScheduleCache = new List<Revenue_Schedule__c>();
		 
		for (Clinic_Budget__c clinicBudget : clinicBudgetList)
		{
			monthSet.add(clinicBudget.Budget_Date__c.month());
			yearSet.add(clinicBudget.Budget_Date__c.year());
			clinicNameSet.add(clinicBudget.Clinic_Name__c);
			
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
		
		for (Invoice_Line__c invoiceLine : [
			SELECT
				Id,
				Clinic__c,
				Accounting_Period__c,
				Clinic_Budget__c
			FROM
				Invoice_Line__c
			WHERE
				CALENDAR_MONTH(Accounting_Period__c) IN :monthSet
			AND
				CALENDAR_YEAR(Accounting_Period__c) IN :yearSet
			AND
				Clinic__c IN :clinicNameSet])
		{
			if (invoiceLine.Clinic_Budget__c != null)
			{
				clinicBudgetSet.add(invoiceLine.Clinic_Budget__c);
				invoiceLine.Clinic_Budget__c = null;
			}
			if (clinicBudgetSearchMap.containsKey(invoiceLine.Clinic__c))
			{
				if (clinicBudgetSearchMap.get(invoiceLine.Clinic__c).containsKey(invoiceline.Accounting_Period__c.year()))
				{
					if (clinicBudgetSearchMap.get(invoiceLine.Clinic__c).get(invoiceline.Accounting_Period__c.year()).
						containsKey(invoiceline.Accounting_Period__c.month()))
					{
						Id clinicBudgetId = clinicBudgetSearchMap.get(invoiceLine.Clinic__c).get(invoiceline.Accounting_Period__c.year()).
							get(invoiceline.Accounting_Period__c.month()).Id;
						invoiceLine.Clinic_Budget__c = clinicBudgetId;
						clinicBudgetSet.add(clinicBudgetId); 
					}
				}
			}
			invoiceLineCache.add(invoiceLine);
		}
		
		for (Revenue_Schedule__c revenueSchedule : [
			SELECT
				id,
				Revenue_Schedule_Date__c,
				Clinic__c,
				Clinic_Budget__c
			FROM
				Revenue_Schedule__c
			WHERE
				CALENDAR_MONTH(Revenue_Schedule_Date__c) IN :monthSet
			AND
				CALENDAR_YEAR(Revenue_Schedule_Date__c) IN :yearSet
			AND
				Clinic__c IN :clinicNameSet])
		{
			if (revenueSchedule.Clinic_Budget__c != null)
			{
				clinicBudgetSet.add(revenueSchedule.Clinic_Budget__c);
				revenueSchedule.Clinic_Budget__c = null;
			}
			if (clinicBudgetSearchMap.containsKey(revenueSchedule.Clinic__c))
			{
				if (clinicBudgetSearchMap.get(revenueSchedule.Clinic__c).containsKey(revenueSchedule.Revenue_Schedule_Date__c.year()))
				{
					if (clinicBudgetSearchMap.get(revenueSchedule.Clinic__c).get(revenueSchedule.Revenue_Schedule_Date__c.year()).
						containsKey(revenueSchedule.Revenue_Schedule_Date__c.month()))
					{
						Id clinicBudgetId = clinicBudgetSearchMap.get(revenueSchedule.Clinic__c).get(revenueSchedule.Revenue_Schedule_Date__c.year()).
							get(revenueSchedule.Revenue_Schedule_Date__c.month()).Id;
						revenueSchedule.Clinic_Budget__c = clinicBudgetId;
						clinicBudgetSet.add(clinicBudgetId);
					}
				}
			}
			revenueScheduleCache.add(revenueSchedule);
		}
		
		if (!invoiceLineCache.isEmpty())
		{
			update invoiceLineCache;
		}
		if (!revenueScheduleCache.isEmpty())
		{
			update revenueScheduleCache;
		}
		
		if (!clinicBudgetSet.isEmpty())
		{
			GSP_SC_ClinicBudgetHelper.RollUpClinicBudgets(clinicBudgetSet);
		}
	}
}