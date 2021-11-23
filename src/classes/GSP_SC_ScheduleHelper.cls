/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, June, 2020
 */
public with sharing class GSP_SC_ScheduleHelper
{
	public static Map<Id, List<Revenue_Schedule__c>> ModifyScheduleStructure(Set<Id> opportunityLineItemSet, Boolean bSave)
	{
		Map<Id, List<Revenue_Schedule__c>> lineItemKeyedScheduleMap = new Map<Id, List<Revenue_Schedule__c>>();
		if ((Schema.sObjectType.Revenue_Schedule__c.isAccessible() &&
			Schema.sObjectType.Schedule_Settings__c.isAccessible() &&
			Schema.sObjectType.Revenue_Schedule__c.isCreateable() &&
			Schema.sObjectType.Opportunity.isAccessible() &&
			Schema.sObjectType.OpportunityLineItem.isAccessible() &&
			Schema.sObjectType.PricebookEntry.isAccessible() &&
			Schema.sObjectType.Product2.isAccessible()) || test.isRunningTest())
		{
			Map<Id, OpportunityLineItem> opportunityLineItemMap = new Map<Id, OpportunityLineItem>();
			Map<Id, OpportunityLineItem> opportunityLineItemCacheMap = new Map<Id, OpportunityLineItem>();
			List<Revenue_Schedule__c> revenueSchedules2Delete = new List<Revenue_Schedule__c>();
			List<Revenue_Schedule__c> revenueScheduleCache = new List<Revenue_Schedule__c>();
			Boolean bIsMultiCurrency = Schema.getGlobalDescribe().containsKey('CurrencyType');
			List<Schedule_Settings__c> scheduleSettings = Schedule_Settings__c.getAll().values();
			Set<Id> opportunitySet = new Set<Id>();
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
					
			String strSOQL = 'SELECT Id, TotalPrice, Revenue_Projection_Method__c, Revenue_Months__c, Revenue_Start_Date__c, Clinic__c,' +
				' Opportunity.IsWon, Opportunity.OwnerId, Opportunity.IsClosed, Opportunity.AccountId, Opportunity.Account.OwnerId,' +
				' PricebookEntry.Product2Id, PricebookEntry.Product2.Family,' +
				' PricebookEntry.Product2.Revenue_Schedule_Method__c, PricebookEntry.Product2.Schedule_Interval_Override__c,' +
				' PricebookEntry.Product2.Default_Revenue_Schedule_Months__c';
			if (bIsMultiCurrency)
			{
				strSOQL += ', CurrencyIsoCode';
			}
			strSOQL += ' FROM OpportunityLineItem WHERE Id IN :opportunityLineItemSet';
			
			for (OpportunityLineItem opportunityLineItem : Database.query(strSOQL))
			{
				opportunitySet.add(opportunityLineItem.OpportunityId);
				opportunityLineItemMap.put(opportunityLineItem.Id, opportunityLineItem);
				lineItemKeyedScheduleMap.put(opportunityLineItem.Id, new List<Revenue_Schedule__c>());
			}
			
			for (Revenue_Schedule__c revenueSchedule : [
				SELECT
					Id,
					Opportunity_Line_Item_Id__c,
					Opportunity__c,
					Account__c,
					Revenue_Schedule_Date__c,
					Revenue_Type__c,
					Product__c,
					Product_Family__c,
					Budget__c,
					Revenue_Amount__c,
					Latest_Forecast__c,
					Cumulative_Revenue__c
				FROM
					Revenue_Schedule__c
				WHERE
					Opportunity_Line_Item_Id__c IN :opportunityLineItemSet
				ORDER BY Opportunity_Line_Item_Id__c, Revenue_Schedule_Date__c])
			{
				System.assertEquals(true, lineItemKeyedScheduleMap.containsKey(revenueSchedule.Opportunity_Line_Item_Id__c));
				lineItemKeyedScheduleMap.get(revenueSchedule.Opportunity_Line_Item_Id__c).add(revenueSchedule);
			}
			
			for (Id id : opportunityLineItemMap.keySet())
			{
				OpportunityLineItem opportunityLineItem = opportunityLineItemMap.get(id);
				System.assertEquals(true, lineItemKeyedScheduleMap.containsKey(id));
				List<Revenue_Schedule__c> revenueScheduleList = lineItemKeyedScheduleMap.get(id);
				Integer nLocalOffset = nGlobalOffset;
				String strLocalInterval = strGlobalInterval;
				
				if (opportunityLineItem.Opportunity.IsClosed && !opportunityLineItem.Opportunity.IsWon)
				{
					continue;
				}
				
				if (opportunityLineItem.Revenue_Months__c == null &&
					(Schema.sObjectType.OpportunityLineItem.fields.Revenue_Months__c.isUpdateable() || test.isRunningTest()))
				{
					if (opportunityLineItem.PricebookEntry.Product2.Default_Revenue_Schedule_Months__c != null &&
						trigger.isInsert)
					{
						opportunityLineItem.Revenue_Months__c = opportunityLineItem.PricebookEntry.Product2.Default_Revenue_Schedule_Months__c;
					}
					else
					{
						opportunityLineItem.Revenue_Months__c = 0;
					}
					opportunityLineItemCacheMap.put(opportunityLineItem.Id, opportunityLineItem);
				}
				
				if (opportunityLineItem.Revenue_Projection_Method__c == null &&
					(Schema.sObjectType.OpportunityLineItem.fields.Revenue_Projection_Method__c.isUpdateable() || test.isRunningTest()))
				{
					if (opportunityLineItem.PricebookEntry.Product2.Revenue_Schedule_Method__c != null &&
						trigger.isInsert)
					{
						opportunityLineItem.Revenue_Projection_Method__c = opportunityLineItem.PricebookEntry.Product2.Revenue_Schedule_Method__c;
						opportunityLineItemCacheMap.put(opportunityLineItem.Id, opportunityLineItem);
					}
				}
				
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
				
				for (Revenue_Schedule__c revenueSchedule : revenueScheduleList)
				{
					if (opportunityLineItem.Revenue_Projection_Method__c != revenueSchedule.Revenue_Type__c &&
						(Schema.sObjectType.Revenue_Schedule__c.fields.Revenue_Type__c.isUpdateable() || test.isRunningTest()))
					{
						revenueSchedule.Revenue_Type__c = opportunityLineItem.Revenue_Projection_Method__c;
					}
				}
				
				// Revenue_Months__c should always be populated
				if (opportunityLineItem.Revenue_Months__c < revenueScheduleList.size() ||
					(opportunityLineItem.Revenue_Start_Date__c == null && !revenueScheduleList.isEmpty()))
				{
					// Schedules to be removed
					Integer revenueMonths = Integer.valueOf(opportunityLineItem.Revenue_Months__c);
					if (opportunityLineItem.Revenue_Start_Date__c == null)
					{
						revenueMonths = 0;
					}
					List<Revenue_Schedule__c> tempRevenueScheduleList = new List<Revenue_Schedule__c>();
					for (Integer i = 0; i < revenueScheduleList.size(); i++)
					{
						if (i < revenueMonths)
						{
							tempRevenueScheduleList.add(revenueScheduleList.get(i));
						}
						else
						{
							revenueSchedules2Delete.add(revenueScheduleList.get(i));
						}
					}
					lineItemKeyedScheduleMap.get(id).clear();
					lineItemKeyedScheduleMap.get(id).addAll(tempRevenueScheduleList);
				}
				else if (opportunityLineItem.Revenue_Start_Date__c != null &&
					opportunityLineItem.Revenue_Projection_Method__c != null &&
					opportunityLineItem.Revenue_Months__c > revenueScheduleList.size())
				{
					Date dt = opportunityLineItem.Revenue_Start_Date__c;
					// Get last Schedule
					if (!revenueScheduleList.isEmpty())
					{
						if (strLocalInterval == 'D')
						{
							dt = revenueScheduleList.get(revenueScheduleList.size() - 1).Revenue_Schedule_Date__c.addDays(nLocalOffset);
						}
						else if (strLocalInterval == 'M')
						{
							dt = revenueScheduleList.get(revenueScheduleList.size() - 1).Revenue_Schedule_Date__c.addMonths(nLocalOffset);
						}
						else if (strLocalInterval == 'Y')
						{
							dt = revenueScheduleList.get(revenueScheduleList.size() - 1).Revenue_Schedule_Date__c.addYears(nLocalOffset);
						}
					}

					Date baseDate = dt;
					Integer index = 1;
					for (Integer i = lineItemKeyedScheduleMap.get(id).size(); i < opportunityLineItem.Revenue_Months__c; i++)
					{
						Revenue_Schedule__c revenueSchedule = new Revenue_Schedule__c(
							Opportunity_Line_Item_Id__c = opportunityLineItem.Id,
							Opportunity__c = opportunityLineItem.OpportunityId,
							Account__c = opportunityLineItem.Opportunity.AccountId,
							Account_Owner__c = opportunityLineItem.Opportunity.Account.OwnerId,
							Revenue_Schedule_Date__c = dt,
							Revenue_Type__c = opportunityLineItem.Revenue_Projection_Method__c,
							Product__c = opportunityLineItem.PricebookEntry.Product2Id,
							Product_Family__c = opportunityLineItem.PricebookEntry.Product2.Family,
							Clinic__c = opportunityLineItem.Clinic__c);
						if (bIsMultiCurrency)
						{
							revenueSchedule.put('CurrencyIsoCode', opportunityLineItem.get('CurrencyIsoCode'));
						}
						if (strLocalInterval == 'D')
						{
							dt = baseDate.addDays(nLocalOffset * index);
						}
						else if (strLocalInterval == 'M')
						{
							dt = baseDate.addMonths(nLocalOffset * index);
						}
						else if (strLocalInterval == 'Y')
						{
							dt = baseDate.addYears(nLocalOffset * index);
						}
						lineItemKeyedScheduleMap.get(id).add(revenueSchedule);
						index++;
					}
					System.assertEquals(opportunityLineItem.Revenue_Months__c, lineItemKeyedScheduleMap.get(id).size());
				}
			}
			
			if (!revenueSchedules2Delete.isEmpty() &&
				(Schema.sObjectType.Revenue_Schedule__c.isDeletable() || test.isRunningTest()))
			{
				delete revenueSchedules2Delete;
			}
			
			RecalculateSchedules(opportunityLineItemMap, lineItemKeyedScheduleMap);
			
			for (Id id : lineItemKeyedScheduleMap.keySet())
			{
				revenueScheduleCache.addAll(lineItemKeyedScheduleMap.get(id));
			}
			
			if (bSave && !revenueScheduleCache.isEmpty() &&
				(Schema.sObjectType.Revenue_Schedule__c.isUpdateable() || test.isRunningTest()))
			{
				upsert revenueScheduleCache;
			}
			
			if (!opportunityLineItemCacheMap.isEmpty() &&
				(Schema.sObjectType.OpportunityLineItem.isUpdateable() || test.isRunningTest()))
			{
				GSP_SC_TriggerContext.DisableOpportunityLineItemTriggers = true;
				update opportunityLineItemCacheMap.values();
				GSP_SC_TriggerContext.DisableOpportunityLineItemTriggers = false;
			}
			if (!lineItemKeyedScheduleMap.isEmpty())
			{
				LinkBudgets(revenueScheduleCache, lineItemKeyedScheduleMap, bSave);
			}
			
			if (!opportunityLineItemMap.isEmpty() &&
				!System.isBatch())
			{
				CalculateSchedules(opportunityLineItemMap.keySet());
			}
		}
		
		return lineItemKeyedScheduleMap;
	}
	
	private static void RecalculateSchedules(Map<Id, OpportunityLineItem> opportunityLineItemMap,
		Map<Id, List<Revenue_Schedule__c>> lineItemKeyedScheduleMap)
	{
		if ((Schema.sObjectType.Revenue_Schedule__c.isAccessible() &&
			Schema.sObjectType.Revenue_Schedule__c.isUpdateable() &&
			Schema.sObjectType.Opportunity.isAccessible() &&
			Schema.sObjectType.OpportunityLineItem.isAccessible()) || test.isRunningTest())
		{
			Integer scale = Schema.sObjectType.Revenue_Schedule__c.fields.Revenue_Amount__c.getScale();
			for (Id id : opportunityLineItemMap.keySet())
			{
				System.assertEquals(true, lineItemKeyedScheduleMap.containsKey(id));
				OpportunityLineItem opportunityLineItem = opportunityLineItemMap.get(id);
				Integer revenueMonths = Integer.valueOf(opportunityLineItem.Revenue_Months__c);
				Integer i;
				Decimal dRunningTotal = 0;
				if (lineItemKeyedScheduleMap.get(id).size() > 0)
				{
					if (opportunityLineitem.Revenue_Projection_Method__c == 'Straight Line')
					{
						if ((Schema.sObjectType.Revenue_Schedule__c.fields.Revenue_Amount__c.isUpdateable() &&
							Schema.sObjectType.Revenue_Schedule__c.fields.Latest_Forecast__c.isUpdateable() &&
							Schema.sObjectType.Revenue_Schedule__c.fields.Cumulative_Revenue__c.isUpdateable()) || test.isRunningTest())
						{
							Decimal dInstallment = ((opportunityLineItem.TotalPrice.setScale(scale) / revenueMonths)).setScale(scale);
							Decimal dFinal = (opportunityLineItem.TotalPrice - (dInstallment * (revenueMonths - 1))).setScale(scale);
							for (i = 0; i < lineItemKeyedScheduleMap.get(id).size(); i++)
							{
								Revenue_Schedule__c revenueSchedule = lineItemKeyedScheduleMap.get(id).get(i);
								
								if (i < (revenueMonths - 1))
								{
									revenueSchedule.Revenue_Amount__c = dInstallment;
								}
								else
								{
									revenueSchedule.Revenue_Amount__c = dFinal;
								}
								revenueSchedule.Latest_Forecast__c = opportunityLineItem.Opportunity.IsWon ? revenueSchedule.Revenue_Amount__c : null;
								revenueSchedule.Cumulative_Revenue__c = dRunningTotal + revenueSchedule.Revenue_Amount__c;
								dRunningTotal += revenueSchedule.Revenue_Amount__c;
							}
						}
					}
					else if (opportunityLineitem.Revenue_Projection_Method__c == 'S-Curve' &&
						(Schema.sObjectType.Revenue_Schedule_Template_Line_Item__c.isAccessible() || test.isRunningTest()))
					{
						Map<Integer, Revenue_Schedule_Template_Line_Item__c> revenueScheduleTemplateLineItemMap =
							new Map<Integer, Revenue_Schedule_Template_Line_Item__c>();
						List<Decimal> dPercentages = new List<Decimal>();
						for (Revenue_Schedule_Template_Line_Item__c revenueScheduleTemplateLineItem : [
							SELECT
								Id,
								Value_This_Month__c,
								Revenue_Schedule_Template__c,
								Previous_Month_Line_Item__c,
								Month__c
							FROM
								Revenue_Schedule_Template_Line_Item__c
							ORDER BY
								Month__c
							LIMIT 200])
						{
							revenueScheduleTemplateLineItemMap.put(Integer.valueOf(revenueScheduleTemplateLineItem.Month__c), revenueScheduleTemplateLineItem);
						}
						System.assertEquals(false, revenueScheduleTemplateLineItemMap.isEmpty(),
							'No S-Curve templates defined, please define templates or use \'Straight Line\'');
						Decimal divisor = (Decimal)revenueScheduleTemplateLineItemMap.size() / (Decimal)revenueMonths;
						Decimal mapIndex = 0;
						Decimal dPercentageTotal = 0;
						
						for (i = 0; i < revenueMonths; i++)
						{
							Date dt = opportunityLineItem.Revenue_Start_Date__c;
							mapIndex += divisor;
							Decimal value;
							Decimal percentage = revenueScheduleTemplateLineItemMap.get(Integer.ValueOf(mapIndex)).Value_This_Month__c;
							if (Integer.valueOf(mapIndex) != mapIndex && mapIndex < revenueScheduleTemplateLineItemMap.size())
							{
								// If we run out of map
								Decimal adjustedPercentage = revenueScheduleTemplateLineItemMap.get(Integer.valueOf(mapIndex)).Value_This_Month__c -
									revenueScheduleTemplateLineItemMap.get(Integer.valueOf(mapIndex + 1)).Value_This_Month__c;
								Decimal actualPercentage = adjustedPercentage * (mapIndex - Integer.valueOf(mapIndex));
								percentage += actualPercentage;
							}
							dPercentages.add(percentage);
							dPercentageTotal += percentage;
						}
						
						System.assertEquals(dPercentages.size(), lineItemKeyedScheduleMap.get(id).size());
						Decimal dTotal = 0;
						for (i = 0; i < lineItemKeyedScheduleMap.get(id).size(); i++)
						{
							if ((Schema.sObjectType.Revenue_Schedule__c.fields.Revenue_Amount__c.isUpdateable() &&
							Schema.sObjectType.Revenue_Schedule__c.fields.Latest_Forecast__c.isUpdateable() &&
							Schema.sObjectType.Revenue_Schedule__c.fields.Cumulative_Revenue__c.isUpdateable()) || test.isRunningTest())
							{
								Revenue_Schedule__c revenueSchedule = lineItemKeyedScheduleMap.get(id).get(i);
								if (i < (dPercentages.size() - 1))
								{
									Decimal dPercentage = dPercentages.get(i);  
									revenueSchedule.Revenue_Amount__c = ((opportunityLineItem.TotalPrice * dPercentage) / dPercentageTotal).setScale(scale);
									dTotal += revenueSchedule.Revenue_Amount__c;
								}
								else
								{
									revenueSchedule.Revenue_Amount__c = (opportunityLineItem.TotalPrice - dTotal).setScale(scale);
								}
								revenueSchedule.Latest_Forecast__c = opportunityLineItem.Opportunity.IsWon ? revenueSchedule.Revenue_Amount__c : null;
								revenueSchedule.Cumulative_Revenue__c = dRunningTotal + revenueSchedule.Revenue_Amount__c;
								dRunningTotal += revenueSchedule.Revenue_Amount__c;
							}
						}
					}
				}
			}
		}
	}

	public static void LinkBudgets(List<Revenue_Schedule__c> revenueScheduleList,
		Map<Id, List<Revenue_Schedule__c>> opportunityLineItemRevenueScheduleMap, Boolean bSave)
	{
		// Map -> Account Owner -> Product -> Year -> Month
		Map<Id, Map<Id, Map<Integer, Map<Integer, Budget__c>>>> budgetUserSearchMap = new Map<Id, Map<Id, Map<Integer, Map<Integer, Budget__c>>>>();
		// Map -> Account Id -> Year -> Month
		Map<Id, Map<Id, Map<Integer, Map<Integer, Budget__c>>>> budgetSearchMap = new Map<Id, Map<Id, Map<Integer, Map<Integer, Budget__c>>>>();
		// Map -> Clinic Name -> Year -> Month
		Map<String, Map<Integer, Map<Integer, Clinic_Budget__c>>> clinicBudgetSearchMap = new Map<String, Map<Integer, Map<Integer, Clinic_Budget__c>>>();
		Set<Integer> monthSet = new Set<Integer>(),
			yearSet = new Set<Integer>();
		Set<Id> budgetSet = new Set<Id>(),
			accountSet = new Set<Id>(),
			accountOwnerSet = new Set<Id>(),
			productSet = new Set<Id>(),
			clinicBudgetSet = new Set<Id>();
		Set<String> clinicNameSet = new Set<String>();
		Map<Id, Revenue_Schedule__c> revenueScheduleCacheMap = new Map<Id, Revenue_Schedule__c>();
		Integer i;
					
		for (Revenue_Schedule__c revenueSchedule : revenueScheduleList)
		{
			monthSet.add(revenueSchedule.Revenue_Schedule_Date__c.month());
			yearSet.add(revenueSchedule.Revenue_Schedule_Date__c.year());
			accountSet.add(revenueSchedule.Account__c);
			accountOwnerSet.add(revenueSchedule.Account_Owner__c);
			productSet.add(revenueSchedule.Product__c);
			if (revenueSchedule.Clinic__c != null)
			{
				clinicNameSet.add(revenueSchedule.Clinic__c);
			}
		}
			
		for (Budget__c budget : [
			SELECT
				Id,
				Account__c,
				Account_Owner__c,
				Budget_Date__c,
				Product__c
			FROM
				Budget__c
			WHERE
				CALENDAR_MONTH(Budget_Date__c) IN :monthSet
			AND
				CALENDAR_YEAR(Budget_Date__c) IN : yearSet
			AND
				Product__c IN :productSet
			AND
				(Account__c IN :accountSet
			OR
				Account_Owner__c IN :accountOwnerSet)])
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
				budgetSearchMap.get(budget.Account__c).get(budget.Product__c).get(budget.Budget_Date__c.year()).put(budget.Budget_Date__c.month(), budget);
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
					budgetUserSearchMap.get(budget.Account_Owner__c).get(budget.Product__c).put(budget.Budget_Date__c.year(), new Map<Integer, Budget__c>());
				}
				budgetUserSearchMap.get(budget.Account_Owner__c).get(budget.Product__c).get(budget.Budget_Date__c.year()).put(budget.Budget_Date__c.month(), budget);
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
				
		for (Id id : opportunityLineItemRevenueScheduleMap.keySet())
		{
			List<Revenue_Schedule__c> revenueSchedules = opportunityLineItemRevenueScheduleMap.get(id);
			for (i = 0; i < revenueSchedules.size(); i++)
			{
				Revenue_Schedule__c revenueSchedule = revenueSchedules.get(i);
				Boolean bFound = false;
				if (i > 0)
				{ 
					revenueSchedule.Previous_Revenue_Schedule__c = revenueSchedules.get(i - 1).Id;
				}
				
				if (revenueSchedule.Budget__c != null)
				{
					budgetSet.add(revenueSchedule.Budget__c);
					revenueSchedule.Budget__c = null;
					revenueScheduleCacheMap.put(revenueSchedule.Id, revenueSchedule);
				}
				
				if (revenueSchedule.Clinic_Budget__c != null)
				{
					clinicBudgetSet.add(revenueSchedule.Clinic_Budget__c);
					revenueSchedule.Clinic_Budget__c = null;
					revenueScheduleCacheMap.put(revenueSchedule.Id, revenueSchedule);
				}
				if (revenueSchedule.Clinic__c != null)
				{
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
								revenueScheduleCacheMap.put(revenueSchedule.Id, revenueSchedule);
								clinicBudgetSet.add(clinicBudgetId);
							}
						}
					}
				}
				
				if (budgetSearchMap.containsKey(revenueSchedule.Account__c))
				{
					if (budgetSearchMap.get(revenueSchedule.Account__c).containsKey(revenueSchedule.Product__c))
					{
						if (budgetSearchMap.get(revenueSchedule.Account__c).get(revenueSchedule.Product__c).
							containsKey(revenueSchedule.Revenue_Schedule_Date__c.year()))
						{
							if (budgetSearchMap.get(revenueSchedule.Account__c).get(revenueSchedule.Product__c).
								get(revenueSchedule.Revenue_Schedule_Date__c.year()).containsKey(revenueSchedule.Revenue_Schedule_Date__c.month()))
							{
								if (Schema.sObjectType.Revenue_Schedule__c.fields.Budget__c.isUpdateable())
								{
									bFound = true;
									Id budgetId = budgetSearchMap.get(revenueSchedule.Account__c).get(revenueSchedule.Product__c).
										get(revenueSchedule.Revenue_Schedule_Date__c.year()).get(revenueSchedule.Revenue_Schedule_Date__c.Month()).Id;
									if (revenueSchedule.Budget__c != budgetId)
									{
										revenueSchedule.Budget__c = budgetId;
										revenueScheduleCacheMap.put(revenueSchedule.Id, revenueSchedule);
										budgetSet.add(revenueSchedule.Budget__c);
									}
								}
							}
						}
					}
				}
				if (!bFound)
				{
					if (budgetUserSearchMap.containsKey(revenueSchedule.Account_Owner__c))
					{
						if (budgetUserSearchMap.get(revenueSchedule.Account_Owner__c).containsKey(revenueSchedule.Product__c))
						{
							if (budgetUserSearchMap.get(revenueSchedule.Account_Owner__c).get(revenueSchedule.Product__c).
								containsKey(revenueSchedule.Revenue_Schedule_Date__c.year()))
							{
								if (budgetUserSearchMap.get(revenueSchedule.Account_Owner__c).get(revenueSchedule.Product__c).
									get(revenueSchedule.Revenue_Schedule_Date__c.year()).containsKey(revenueSchedule.Revenue_Schedule_Date__c.month()))
								{
									if (Schema.sObjectType.Revenue_Schedule__c.fields.Budget__c.isUpdateable())
									{
										bFound = true;
										Id budgetId = budgetUserSearchMap.get(revenueSchedule.Account_Owner__c).get(revenueSchedule.Product__c).
											get(revenueSchedule.Revenue_Schedule_Date__c.year()).get(revenueSchedule.Revenue_Schedule_Date__c.Month()).Id;
										if (revenueSchedule.Budget__c != budgetId)
										{
											revenueSchedule.Budget__c = budgetId;
											revenueScheduleCacheMap.put(revenueSchedule.Id, revenueSchedule);
											budgetSet.add(revenueSchedule.Budget__c);
										}
									}
								}
							}
						}
					}
				}
				if (!bFound)
				{
					budgetSet.add(revenueSchedule.Budget__c);
					revenueScheduleCacheMap.put(revenueSchedule.Id, revenueSchedule);
				}
			}
		}
		if (bSave && !revenueScheduleCachemap.isEmpty())
		{
			update revenueScheduleCacheMap.values();
		}
				
		if (!budgetSet.isEmpty())
		{
			GSP_SC_BudgetHelper.RollUpScheduleValues(budgetSet);
		}
		
		if (!clinicBudgetSet.isEmpty())
		{
			GSP_SC_ClinicBudgetHelper.RollUpClinicBudgets(clinicBudgetSet);
		}
	}
	
	@future
	public static void CalculateSchedules(Set<Id> opportunityLineItemSet)
	{
		Map<Id, OpportunityLineItem> opportunityLineItemMap = new Map<Id, OpportunityLineItem>();
		Map<Id, List<Revenue_Schedule__c>> lineItemKeyedScheduleMap = new Map<Id, List<Revenue_Schedule__c>>();
		List<OpportunityLineItem> opportunityLineItemCache = new List<OpportunityLineItem>();

		for (OpportunityLineItem opportunityLineItem : [
			SELECT
				Id,
				Revenue_Months__c
			FROM
				OpportunityLineItem
			WHERE
				Id IN :opportunityLineItemSet])
		{
			opportunityLineItemMap.put(opportunityLineItem.Id, opportunityLineItem);
			lineItemKeyedScheduleMap.put(opportunityLineItem.Id, new List<Revenue_Schedule__c>());
		}
		
		for (Revenue_Schedule__c revenueSchedule : [
			SELECT
				Id,
				Opportunity_Line_Item_Id__c
			FROM
				Revenue_Schedule__c
			WHERE
				Opportunity_Line_Item_Id__c IN :opportunityLineItemSet])
		{
			System.assertEquals(true, lineItemKeyedScheduleMap.containsKey((Id)revenueSchedule.Opportunity_Line_Item_Id__c));
			lineItemKeyedScheduleMap.get((Id)revenueSchedule.Opportunity_Line_Item_Id__c).add(revenueSchedule);
		}
		
		for (Id id : opportunityLineItemMap.keySet())
		{
			System.assertEquals(true, lineItemKeyedScheduleMap.containsKey(id));
			OpportunityLineItem opportunityLineItem = opportunityLineItemMap.get(id);
			if (opportunityLineItem.Revenue_Months__c != lineItemKeyedScheduleMap.get(id).size())
			{
				opportunityLineItem.Revenue_Months__c = lineItemKeyedScheduleMap.get(id).size();
				opportunityLineItemCache.add(opportunityLineItem);
			}
		}
		
		if (!opportunityLineItemCache.isEmpty())
		{
			GSP_SC_TriggerContext.DisableOpportunityLineItemTriggers = true;
			update opportunityLineItemCache;
			GSP_SC_TriggerContext.DisableOpportunityLineItemTriggers = false;
		}
	}
	
	public static void BatchUpdateSalesforceSchedules(List<OpportunityLineItem> opportunityLineItemList, String projectionType)
	{
		Set<Id> opportunityLineItemSet = new Set<Id>();
		Set<Id> lineItemRevenueSet = new Set<Id>();
		Map<Id, List<sObject>> lineItemKeyedScheduleMap = new Map<Id, List<sObject>>();
		List<sObject> opportunityLineItemSchedules2delete = new List<sObject>();
		List<Revenue_Schedule__c> revenueScheduleCache = new List<Revenue_Schedule__c>();
		List<OpportunityLineItem> opportunityLineItemCache = new List<OpportunityLineItem>();
		for (OpportunityLineItem opportunityLineItem : opportunityLineItemList)
		{
			opportunityLineItemSet.add(opportunityLineItem.Id);
		}
		
		String strSOQL = 'SELECT Id, HasSchedule, HasRevenueSchedule, Quantity, TotalPrice, (SELECT Type, Revenue, ScheduleDate FROM OpportunityLineItemSchedules' +
			' ORDER BY ScheduleDate) FROM OpportunityLineItem WHERE Id IN :opportunityLineItemSet';
		for (OpportunityLineItem opportunityLineItem : Database.query(strSOQL))
		{
			if (opportunityLineItem.get('HasRevenueSchedule') == true)
			{
				lineItemRevenueSet.add(opportunityLineItem.Id);
				lineItemKeyedScheduleMap.put(opportunityLineItem.Id, opportunityLineItem.getSObjects('OpportunityLineItemSchedules'));
				opportunityLineItem.Revenue_Months__c = opportunityLineItem.getSObjects('OpportunityLineItemSchedules').size();
				opportunityLineItem.Revenue_Start_Date__c = (Date)opportunityLineItem.getSObjects('OpportunityLineItemSchedules').get(0).get('ScheduleDate');
				opportunityLineItem.Revenue_Projection_Method__c = projectionType;
				opportunityLineItemCache.add(opportunityLineItem);
			}			
			opportunityLineItemSchedules2delete.addAll(opportunityLineItem.getSObjects('OpportunityLineItemSchedules'));
		}
		// Prevent automatic schedule creation
		GSP_SC_TriggerContext.DisableOpportunityLineItemTriggers = true;
		update opportunityLineItemCache;
		// Manually create schedules
		Map<Id, List<Revenue_Schedule__c>> opportunityLineItemRevenueScheduleMap = ModifyScheduleStructure(lineItemRevenueSet, false);
		for (Id id : opportunityLineItemRevenueScheduleMap.keySet())
		{
			revenueScheduleCache.addAll(opportunityLineItemRevenueScheduleMap.get(id));
			if (lineItemKeyedScheduleMap.containsKey(id))
			{
				System.assertEquals(lineItemKeyedScheduleMap.get(id).size(), opportunityLineItemRevenueScheduleMap.get(id).size());
				for (Integer i = 0; i < opportunityLineItemRevenueScheduleMap.get(id).size(); i++)
				{
					Revenue_Schedule__c revenueSchedule = opportunityLineItemRevenueScheduleMap.get(id).get(i);
					SObject opportunityLineItemSchedule = lineItemKeyedScheduleMap.get(id).get(i);
					revenueSchedule.Revenue_Schedule_Date__c = (Date)opportunityLineItemSchedule.get('ScheduleDate');
					revenueSchedule.Revenue_Amount__c = (Decimal)opportunityLineItemSchedule.get('Revenue');
				}
			}
		}
		delete opportunityLineItemSchedules2delete;
		GSP_SC_TriggerContext.DisableRevenueScheduleTriggers = true;
		insert revenueScheduleCache;
		GSP_SC_TriggerContext.DisableRevenueScheduleTriggers = false;
		
		GSP_SC_TriggerContext.DisableOpportunityLineItemTriggers = true;
		update opportunityLineItemCache;
		GSP_SC_TriggerContext.DisableOpportunityLineItemTriggers = false;
		LinkBudgets(revenueScheduleCache, opportunityLineItemRevenueScheduleMap, true);
	}
}