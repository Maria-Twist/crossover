/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, June, 2020
 */
@isTest
private class GSP_SC_ScheduleHelper_TEST
{
	@isTest(seeAlldata=true)
	private static void test_BatchUpdateSalesforceSchedules()
	{
		if (Schema.getGlobalDescribe().containsKey('OpportunityLineItemSchedule'))
		{
			Integer PRODUCT_CHUNK = 3;
			Integer REVENUE_MONTHS = 12;
			Integer LINE_ITEM_CHUNK = 4;
			Integer SCHEDULE_CHUNK = 3;
			Set<Id> opportunityLineItemSet = new Set<Id>();
			Set<Id> budgetSet = new set<Id>();
			List<Product2> productCache = new List<Product2>();
			List<PricebookEntry> pricebookEntryCache = new List<PricebookEntry>();
			List<PricebookEntry> standardPricebookEntryCache = new List<PricebookEntry>();
			List<OpportunityLineItem> opportunityLineItemCache = new List<OpportunityLineItem>();
			List<Budget__c> budgetCache = new List<Budget__c>();
			List<sObject> opportunityLineItemScheduleCache = new List<sObject>();
			Map<Id, OpportunityLineItem> opportunityLineItemMap = new Map<Id, OpportunityLineItem>();
			Map<String, List<Revenue_Schedule__c>> testRevenueScheduleMap = new Map<String, List<Revenue_Schedule__c>>(); 
			Pricebook2 pricebook, standardPricebook;
			Integer i, j;
			
			List<Schedule_Settings__c> scheduleSettings = Schedule_Settings__c.getAll().values();
			if (!scheduleSettings.isEmpty())
			{
				for (Schedule_Settings__c scheduleSetting : scheduleSettings)
				{
					scheduleSetting.Global_Schedule_Interval__c = 'M1';
				}
				update scheduleSettings;
			}
			else
			{
				Schedule_Settings__c setting = new Schedule_Settings__c(
					Name = 'Default',
					Global_Schedule_Interval__c = 'M1');
				insert setting;
				System.assertNotEquals(setting.Id, null);
			}
			
			for (Pricebook2 pricebook2 : [
				SELECT
					Id,
					IsStandard,
					IsActive
				FROM
					Pricebook2
				WHERE
					IsStandard = true
				OR
					IsActive = true])
			{
				if (pricebook2.isStandard)
				{
					standardPricebook = pricebook2;
				}
				if (pricebook2.isActive)
				{
					pricebook = pricebook2;
					if (pricebook2.isStandard)
					{
						standardPricebook = pricebook2;
						break;
					}
				}
			}
			
			for (i = 0; i < PRODUCT_CHUNK; i++)
			{
				Product2 product = new Product2(
					Name = 'Product ' + i,
					IsActive = true);
					try
					{
						product.put('CanUseRevenueSchedule', true);
					}
					catch (Exception ex){}
					try
					{
						product.put('CanUseQuantitySchedule', true);
					}
					catch (Exception ex){}
				productCache.add(product);
			}
			insert productCache;
			
			for (i = 0; i < PRODUCT_CHUNK; i++)
			{
				if (pricebook != standardPricebook)
				{
					PricebookEntry pricebookEntry = new PricebookEntry(
						Pricebook2Id = standardPricebook.Id,
						Product2Id = productCache.get(i).Id,
						UnitPrice = (i + 1) * 7,
						IsActive = standardPricebook.isActive);
					standardPricebookEntryCache.add(pricebookEntry);
				}
				PricebookEntry pricebookEntry = new PricebookEntry(
					Pricebook2Id = pricebook.Id,
					Product2Id = productCache.get(i).Id,
					UnitPrice = (i + 1) * 7,
					IsActive = true);
				pricebookEntrycache.add(pricebookEntry);
			}
			
			if (!standardPricebookEntryCache.isEmpty())
			{
				insert standardPricebookEntryCache;
			}
			insert pricebookEntryCache;

			Account account = new Account(
				Name = 'Apex Test Account');
			insert account;
			System.assertNotEquals(account.Id, null);
			
			Date dtBudget = Date.today().addYears(10).toStartOfMonth();
			for (i = 0; i < 12; i++)
			{
				for (Product2 product : productCache)
				{
					Budget__c budget = new Budget__c(
						Budget_Date__c = dtBudget.addMonths(i),
						Account__c = account.Id,
						Product__c = product.Id);
					budgetCache.add(budget);
				}
			}
			insert budgetCache;
			for (Budget__c budget : budgetCache)
			{
				budgetSet.add(budget.Id);
			}
			
			Opportunity opportunity = new Opportunity(
				Name = 'Apex Test Opportunity',
				StageName = 'Prospecting',
				CloseDate = Date.today().addYears(10),
				AccountId = account.Id,
				Revenue_Type__c = '	New Business');
			insert opportunity;
			System.assertNotEquals(opportunity.Id, null);
			
			for (i = 0; i < LINE_ITEM_CHUNK; i++)
			{
				OpportunityLineItem opportunityLineItem = new OpportunityLineItem(
					OpportunityId = opportunity.Id,
					PricebookEntryId = pricebookEntryCache.get(i == 3 ? i - 1 : i).Id,
					UnitPrice = 12000,
					Quantity = 1,
					Pricing_Model__c = 'PEPM');
				opportunityLineItemCache.add(opportunityLineItem);
			}
			
			GSP_SC_TriggerContext.DisableOpportunityLineItemTriggers = true;		// Prevent schedule creation
			insert opportunityLineItemCache;
			
			for (opportunityLineItem opportunityLineItem : opportunityLineItemCache)
			{
				opportunityLineItemSet.add(opportunityLineItem.Id);
				Date dt = Date.today().addYears(10);
				for (i = 0; i < SCHEDULE_CHUNK; i++)
				{
					sObject schedule = Schema.getGlobalDescribe().get('OpportunityLineItemSchedule').newSObject();
					schedule.put('Type', 'Revenue');
					schedule.put('ScheduleDate', dt);
					schedule.put('Revenue', 1000 * i);
					schedule.put('OpportunityLineItemId', opportunityLineItem.Id);
					opportunityLineItemScheduleCache.add(schedule);
					dt = dt.addMonths(1);
				}
			}
			insert opportunityLineItemScheduleCache;
			
			String strSOQL = 'SELECT Id, HasSchedule, TotalPrice, (SELECT Type, Revenue, ScheduleDate FROM OpportunityLineItemSchedules' +
				' ORDER BY ScheduleDate) FROM OpportunityLineItem WHERE Id IN :opportunityLineItemSet';
			
			List<OpportunityLineItem> testOpportunityLineItems = Database.query(strSOQL);
			System.assertEquals(LINE_ITEM_CHUNK, testOpportunityLineItems.size());
			for (OpportunityLineItem testOpportunityLineItem : testOpportunityLineItems)
			{
				System.assertEquals(SCHEDULE_CHUNK, testOpportunityLineItem.getSObjects('OpportunityLineItemSchedules').size());
			}
			
			GSP_SC_ScheduleHelper.BatchUpdateSalesforceSchedules(opportunityLineItemCache, 'Straight Line');
			
			testOpportunityLineItems = Database.query(strSOQL);
			System.assertEquals(LINE_ITEM_CHUNK, testOpportunityLineItems.size());
			for (OpportunityLineItem testOpportunityLineItem : testOpportunityLineItems)
			{
				System.assertEquals(null, testOpportunityLineItem.getSObjects('OpportunityLineItemSchedules'));	// All salesforce schedules deleted
			}
		}
	}
}