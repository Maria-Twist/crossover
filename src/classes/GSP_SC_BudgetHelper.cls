/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, 20 Jul 2020
 */
public with sharing class GSP_SC_BudgetHelper
{
	@TestVisible
	private static Map<String, Decimal> currencyMap = new Map<String, Decimal>();
	@TestVisible
	private static Boolean bIsMulticurrency = Schema.getGlobalDescribe().containsKey('CurrencyType');
	
	public static void RollUpScheduleValues(Set<Id> budgetSet)
	{
		List<Budget__c> budgetCache = new List<Budget__c>();
		
		if (bIsMulticurrency)
		{
			String strCurrencyType = 'SELECT IsoCode, ConversionRate FROM CurrencyType';
	
			for (Sobject currencyType : Database.query(strCurrencyType))
			{
				GSP_SC_BudgetHelper.currencyMap.put(String.valueOf(currencyType.get('IsoCode')), (Decimal)(currencyType.get('ConversionRate')));
			}
		}
		
		String strSOQL = 'SELECT Id, Name, Won_Revenue__c, Weighted_Revenue__c, Pipeline_Revenue__c,';
		if (bIsMulticurrency)
		{
			strSOQL += ' CurrencyIsoCode,';
		}
		strSOQL += ' (SELECT Revenue_Amount__c, Weighted_Revenue_Amount__c, Opportunity__c, Opportunity__r.isClosed, Opportunity__r.isWon';
		if (bIsMulticurrency)
		{
			strSOQL += ' ,CurrencyIsoCode';
			
		}
		strSOQL += ' FROM Revenue_Schedules__r ORDER BY Account__c) FROM Budget__c WHERE Id IN :budgetSet';
		
		for (Budget__c budget : Database.query(strSOQL))
		{
			budget.Won_Revenue__c =
			budget.Weighted_Revenue__c =
			budget.Pipeline_Revenue__c = 0;
			for (Revenue_Schedule__c revenueSchedule : budget.Revenue_Schedules__r)
			{				
				if (revenueSchedule.Opportunity__r.IsClosed)
				{
					if (revenueSchedule.Opportunity__r.IsWon)
					{
						if (bIsMulticurrency)
						{
							budget.Won_Revenue__c += revenueSchedule.Revenue_Amount__c == null ? 0 :
								ConvertCurrency(revenueSchedule.Revenue_Amount__c, String.valueOf(revenueSchedule.get('CurrencyIsoCode')), String.valueOf(budget.get('CurrencyIsoCode')));
						}
						else
						{
							budget.Won_Revenue__c += revenueSchedule.Revenue_Amount__c == null ? 0 : revenueSchedule.Revenue_Amount__c;
						}
					}
				}
				else
				{
					if (bIsMulticurrency)
					{
						budget.Pipeline_Revenue__c += revenueSchedule.Revenue_Amount__c == null ? 0 :
							ConvertCurrency(revenueSchedule.Revenue_Amount__c, String.valueOf(revenueSchedule.get('CurrencyIsoCode')), String.valueOf(budget.get('CurrencyIsoCode')));
						budget.Weighted_Revenue__c += revenueSchedule.Weighted_Revenue_Amount__c == null ? 0 :
							ConvertCurrency(revenueSchedule.Weighted_Revenue_Amount__c, String.valueOf(revenueSchedule.get('CurrencyIsoCode')), String.valueOf(budget.get('CurrencyIsoCode')));
					}
					else
					{
						budget.Pipeline_Revenue__c += revenueSchedule.Revenue_Amount__c == null ? 0 : revenueSchedule.Revenue_Amount__c;
						budget.Weighted_Revenue__c += revenueSchedule.Weighted_Revenue_Amount__c == null ? 0 : revenueSchedule.Weighted_Revenue_Amount__c;
					}
				}
			}
			budgetCache.add(budget);
		}
		if (!budgetCache.isEmpty())
		{
			update budgetCache;
		}
	}
	
	public static void RollUpInvoiceValues(Set<Id> budgetSet)
	{
		List<Budget__c> budgetCache = new List<Budget__c>();
		if (bIsMulticurrency)
		{
			String strCurrencyType = 'SELECT IsoCode, ConversionRate FROM CurrencyType';
	
			for (Sobject currencyType : Database.query(strCurrencyType))
			{
				GSP_SC_BudgetHelper.currencyMap.put(String.valueOf(currencyType.get('IsoCode')), (Decimal)(currencyType.get('ConversionRate')));
			}
		}
		
		String strSOQL = 'SELECT Id, Name, Invoice_Total_Amount__c,';
		if (bIsMulticurrency)
		{
			strSOQL += ' CurrencyIsoCode,';
		}
		strSOQL += ' (SELECT Id, Amount__c';
		if (bIsMulticurrency)
		{
			strSOQL += ' ,CurrencyIsoCode';
			
		}
		strSOQL += ' FROM Invoice_Lines__r) FROM Budget__c WHERE Id IN :budgetSet';
		
		for (Budget__c budget : Database.query(strSOQL))
		{
			budget.Invoice_Total_Amount__c = 0;
			for (Invoice_Line__c invoiceLine : budget.Invoice_Lines__r)
			{
				if (bIsMulticurrency)
				{
					budget.Invoice_Total_Amount__c += invoiceLine.Amount__c == null ? 0 :
					ConvertCurrency(invoiceLine.Amount__c, String.valueOf(invoiceLine.get('CurrencyIsoCode')), String.valueOf(budget.get('CurrencyIsoCode')));
				}
				else
				{
					budget.Invoice_Total_Amount__c += invoiceLine.Amount__c == null ? 0 : invoiceLine.Amount__c;
				}
			}
			budgetCache.add(budget);
		}
		if (!budgetCache.isEmpty())
		{
			update budgetCache;
		}
	}
	
	@TestVisible
	private static Decimal ConvertCurrency(Decimal amount, String sourceCurrencyIsoCode, String targetCurrencyIsoCode)
	{
		if (amount == null)
		{
			return 0;
		}
		System.assertEquals(true, GSP_SC_BudgetHelper.currencyMap.containsKey(sourceCurrencyIsoCode));
		System.assertEquals(true, GSP_SC_BudgetHelper.currencyMap.containsKey(targetCurrencyIsoCode));
		return (amount * (GSP_SC_BudgetHelper.currencyMap.get(targetCurrencyIsoCode) /
			GSP_SC_BudgetHelper.currencyMap.get(sourceCurrencyIsoCode))).setScale(2);
	} 
}