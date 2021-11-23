/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, 23 Oct 2020
 */
public with sharing class GSP_SC_ClinicBudgetHelper
{
	@TestVisible
	private static Map<String, Decimal> currencyMap = new Map<String, Decimal>();
	@TestVisible
	private static Boolean bIsMulticurrency = Schema.getGlobalDescribe().containsKey('CurrencyType');
	
    public static void RollUpClinicBudgets(Set<Id> clinicBudgetSet)
    {
    	List<Clinic_Budget__c> clinicBudgetCache = new List<Clinic_Budget__c>();
		
		if (bIsMulticurrency)
		{
			String strCurrencyType = 'SELECT IsoCode, ConversionRate FROM CurrencyType';
	
			for (Sobject currencyType : Database.query(strCurrencyType))
			{
				GSP_SC_ClinicBudgetHelper.currencyMap.put(String.valueOf(currencyType.get('IsoCode')), (Decimal)(currencyType.get('ConversionRate')));
			}
		}
		
		String strSOQL = 'SELECT Id, Invoice_Amount__c, Pipeline_Scheduled_Revenue__c, Won_Scheduled_Revenue__c,';
		if (bIsMulticurrency)
		{
			strSOQL += ' CurrencyIsoCode,';
		}
		strSOQL += ' (SELECT Id, Opportunity__r.IsWon, Opportunity__r.IsClosed, Revenue_Amount__c';
		if (bIsMulticurrency)
		{
			strSOQL += ', CurrencyIsoCode';
		}
		strSOQL += ' FROM Revenue_Schedules__r), (SELECT Id, Amount__c';
		if (bIsMulticurrency)
		{
			strSOQL += ', CurrencyIsoCode';
		}
		strSOQL += ' FROM Invoice_Lines__r) FROM Clinic_Budget__c WHERE	Id IN :clinicBudgetSet';
		
    	for (Clinic_Budget__c clinicBudget : Database.query(strSOQL))
    	{
    		clinicBudget.Invoice_Amount__c =
    		clinicBudget.Pipeline_Scheduled_Revenue__c =
    		clinicBudget.Won_Scheduled_Revenue__c = 0;
    		
    		for (Revenue_Schedule__c revenueSchedule : clinicBudget.Revenue_Schedules__r)
    		{
    			if (revenueSchedule.Opportunity__r.IsWon)
    			{
    				if (bIsMulticurrency)
    				{
    					clinicBudget.Won_Scheduled_Revenue__c += revenueSchedule.Revenue_Amount__c == null ? 0 :
    						ConvertCurrency(revenueSchedule.Revenue_Amount__c, String.valueOf(revenueSchedule.get('CurrencyIsoCode')),
    						String.valueOf(clinicBudget.get('CurrencyIsoCode')));
    				}
    				else
    				{
    					clinicBudget.Won_Scheduled_Revenue__c += revenueSchedule.Revenue_Amount__c == null ? 0 : revenueSchedule.Revenue_Amount__c;
    				} 
    			}
    			else if (!revenueSchedule.Opportunity__r.IsClosed)
    			{
    				if (bIsMulticurrency)
    				{
    					clinicBudget.Pipeline_Scheduled_Revenue__c += revenueSchedule.Revenue_Amount__c == null ? 0 :
    						ConvertCurrency(revenueSchedule.Revenue_Amount__c, String.valueOf(revenueSchedule.get('CurrencyIsoCode')),
    						String.valueOf(clinicBudget.get('CurrencyIsoCode')));
    				}
    				else
    				{
    					clinicBudget.Pipeline_Scheduled_Revenue__c += revenueSchedule.Revenue_Amount__c == null ? 0 : revenueSchedule.Revenue_Amount__c;
    				} 
    			}
    		}
    		
    		for (Invoice_Line__c invoiceLine : clinicBudget.Invoice_Lines__r)
    		{
    			clinicBudget.Invoice_Amount__c += invoiceLine.Amount__c == null ? 0 : invoiceLine.Amount__c;
    		}
    		clinicBudgetCache.add(clinicBudget);
    	}
    	
    	if (!clinicBudgetCache.isEmpty())
    	{
    		update clinicBudgetCache;
    	}
    }
    
    @TestVisible
	private static Decimal ConvertCurrency(Decimal amount, String sourceCurrencyIsoCode, String targetCurrencyIsoCode)
	{
		if (amount == null)
		{
			return 0;
		}
		System.assertEquals(true, GSP_SC_ClinicBudgetHelper.currencyMap.containsKey(sourceCurrencyIsoCode));
		System.assertEquals(true, GSP_SC_ClinicBudgetHelper.currencyMap.containsKey(targetCurrencyIsoCode));
		return (amount * (GSP_SC_ClinicBudgetHelper.currencyMap.get(targetCurrencyIsoCode) /
			GSP_SC_ClinicBudgetHelper.currencyMap.get(sourceCurrencyIsoCode))).setScale(2);
	} 
}