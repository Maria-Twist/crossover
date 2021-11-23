/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, June, 2020
 */
public with sharing class GSP_SC_trgRevenueScheduleMethods
{
	@TestVisible
	private static Map<String, Decimal> currencyMap = new Map<String, Decimal>();
	// Is multicurrency enabled
	@TestVisible
	private static Boolean bIsMulticurrency = Schema.getGlobalDescribe().containsKey('CurrencyType');
	
	public static void UpdateOpportunityLineItemValues(List<Revenue_Schedule__c> revenueScheduleList)
	{
		// ACM Roll Ups
		UpdateOpportunityRollUpFields(revenueScheduleList);
			
		if ((Schema.sObjectType.OpportunityLineItem.isUpdateable() &&
			Schema.sObjectType.Revenue_Schedule__c.isAccessible()) ||
			test.isRunningTest())
		{
			List<OpportunityLineItem> opportunityLineItemCache = new List<OpportunityLineItem>();
			Map<String, List<Revenue_Schedule__c>> opportunityLineItemKeyedRevenueScheduleMap = new Map<String, List<Revenue_Schedule__c>>();
			
			for (Revenue_Schedule__c revenueSchedule : revenueScheduleList)
			{
				if (!opportunityLineItemKeyedRevenueScheduleMap.containsKey(revenueSchedule.Opportunity_Line_Item_Id__c))
				{
					opportunityLineItemKeyedRevenueScheduleMap.put(revenueSchedule.Opportunity_Line_Item_Id__c, new List<Revenue_Schedule__c>());
				}
			}
			
			for (Revenue_Schedule__c revenueSchedule : [
				SELECT
					Id,
					Revenue_Amount__c,
					Opportunity_Line_Item_Id__c
				FROM
					Revenue_Schedule__c
				WHERE
					Opportunity_Line_Item_Id__c IN :opportunityLineItemKeyedRevenueScheduleMap.keySet()])
			{
				if (opportunityLineItemKeyedRevenueScheduleMap.containsKey(revenueSchedule.Opportunity_Line_Item_Id__c))
				{
					opportunityLineItemKeyedRevenueScheduleMap.get(revenueSchedule.Opportunity_Line_Item_Id__c).add(revenueSchedule);
				}
			}
					for (OpportunityLineItem opportunityLineItem : [
				SELECT
					Id,
					UnitPrice,
					TotalPrice,
					Quantity,
					Discount
				FROM
					OpportunityLineItem
				WHERE
					Id IN :opportunityLineItemKeyedRevenueScheduleMap.keySet()])
			{
				if (opportunityLineItemKeyedRevenueScheduleMap.containsKey(opportunityLineItem.Id))
				{
					Decimal dTotal = 0;
					if (Schema.sObjectType.OpportunityLineItem.fields.UnitPrice.isUpdateable() ||
						test.isRunningTest())
					{
						for (Revenue_Schedule__c revenueSchedule : opportunityLineItemKeyedRevenueScheduleMap.get(opportunityLineItem.Id))
						{
							dTotal += revenueSchedule.Revenue_Amount__c;
						}
						if (opportunityLineItem.TotalPrice != dTotal)
						{
							opportunityLineItem.TotalPrice = dTotal;
							opportunityLineItemCache.add(opportunityLineItem);
						}
					}
				}
			}
			if (!opportunityLineItemCache.isEmpty() &&
				(Schema.sObjectType.OpportunityLineItem.isDeletable() ||
				test.isRunningTest()))
			{
				GSP_SC_TriggerContext.DisableOpportunityLineItemTriggers = true;
				update opportunityLineItemCache;
			}
		}
	}
	
	public static void UpdateOpportunityRollUpFields(List<Revenue_Schedule__c> revenueScheduleList)
	{
		if ((Schema.sObjectType.Opportunity.isAccessible() &&
			Schema.sObjectType.Opportunity.isUpdateable()) ||
			test.isRunningTest())
		{
			// Get conversions if Multi Currency enabled
			if (bIsMulticurrency)
			{
				String strCurrencyType = 'SELECT IsoCode, ConversionRate FROM CurrencyType';
				for (Sobject currencyType : Database.query(strCurrencyType))
				{
					GSP_SC_trgRevenueScheduleMethods.currencyMap.put(String.valueOf(currencyType.get('IsoCode')), (Decimal)(currencyType.get('ConversionRate')));
				}
			}
			
			Set<Id> opportunitySet = new Set<Id>();
			List<Opportunity> opportunityCache = new List<Opportunity>();
			for (Revenue_Schedule__c revenueSchedule : revenueScheduleList)
			{
				opportunitySet.add(revenueSchedule.Opportunity__c);
			}
			
			String strSOQL = 'SELECT Id, Total_Actual__c, Total_Latest_Forecast__c, Total_Schedule_Revenue__c, ';
			if (bIsMulticurrency)
			{
				strSOQL += ' CurrencyIsoCode,';
			}
			strSOQL += ' (SELECT Id, Actual__c, Latest_Forecast__c, Revenue_Amount__c';
			if (bIsMulticurrency)
			{
				strSOQL += ', CurrencyIsoCode';
			}
			strSOQL += ' FROM Revenue_Schedules__r) FROM Opportunity WHERE Id IN :opportunitySet';
	
			for (Opportunity opportunity : Database.query(strSOQL))
			{
				if ((Schema.sObjectType.Opportunity.fields.Total_Actual__c.isUpdateable() &&
					Schema.sObjectType.Opportunity.fields.Total_Latest_Forecast__c.isUpdateable() &&
					Schema.sObjectType.Opportunity.fields.Total_Schedule_Revenue__c.isUpdateable()) ||
					test.isRunningTest())
				{
					opportunity.Total_Actual__c =
					opportunity.Total_Latest_Forecast__c =
					opportunity.Total_Schedule_Revenue__c = 0;
					for (Revenue_Schedule__c revenueSchedule : opportunity.Revenue_Schedules__r)
					{
						opportunity.Total_Actual__c += revenueSchedule.Actual__c == null ? 0 : bIsMulticurrency ? ConvertCurrency(
							revenueSchedule.Actual__c, (String)revenueSchedule.get('CurrencyIsoCode'),
							(String)opportunity.get('CurrencyIsoCode')) : revenueSchedule.Actual__c;
							
						opportunity.Total_Latest_Forecast__c += revenueSchedule.Latest_Forecast__c == null ? 0 : bIsMulticurrency ? ConvertCurrency(
							revenueSchedule.Latest_Forecast__c,	(String)revenueSchedule.get('CurrencyIsoCode'),
							(String)opportunity.get('CurrencyIsoCode')) : revenueSchedule.Latest_Forecast__c;
							
						opportunity.Total_Schedule_Revenue__c += revenueSchedule.Revenue_Amount__c == null ? 0 : bIsMulticurrency ? ConvertCurrency(
							revenueSchedule.Revenue_Amount__c, (String)revenueSchedule.get('CurrencyIsoCode'),
							(String)opportunity.get('CurrencyIsoCode')) : revenueSchedule.Revenue_Amount__c;
					}
					opportunityCache.add(opportunity);
				}
			}
			
			if (!opportunityCache.isEmpty())
			{
				GSP_SC_TriggerContext.DisableOpportunityLineItemTriggers = true;
				update opportunityCache;
			}
		}
	}
	
	public static void UpdateTargetsOnDelete(List<Revenue_Schedule__c> revenueScheduleList)
	{
		// ACM Roll Ups
		UpdateOpportunityRollUpFields(revenueScheduleList);
			
		Set<Id> budgetSet = new Set<Id>();
		for (Revenue_Schedule__c revenueSchedule : revenueScheduleList)
		{
			if (revenueSchedule.Budget__c != null)
			{
				budgetSet.add(revenueSchedule.Budget__c);
			}
		}
		if (!budgetSet.isEmpty())
		{
			GSP_SC_BudgetHelper.RollUpScheduleValues(budgetSet);
		}
	}
	
	@TestVisible
	private static Decimal ConvertCurrency(Decimal amount, String sourceCurrencyIsoCode, String targetCurrencyIsoCode)
	{
		Decimal dReturnValue = null;
		if (amount == null)
		{
			return 0;
		}
		System.assertEquals(true, GSP_SC_trgRevenueScheduleMethods.currencyMap.containsKey(sourceCurrencyIsoCode));
		System.assertEquals(true, GSP_SC_trgRevenueScheduleMethods.currencyMap.containsKey(targetCurrencyIsoCode));
		dReturnValue = (amount * (GSP_SC_trgRevenueScheduleMethods.currencyMap.get(targetCurrencyIsoCode) /
			GSP_SC_trgRevenueScheduleMethods.currencyMap.get(sourceCurrencyIsoCode))).setScale(2); 
		return dReturnValue;
	}
}