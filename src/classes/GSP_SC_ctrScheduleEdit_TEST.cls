/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, June, 2020
 */
@isTest
private class GSP_SC_ctrScheduleEdit_TEST
{
	@isTest(seeAllData=true)
	private static void test_GSP_SC_ctrScheduleEdit()
	{
		Integer PRODUCT_CHUNK = 3;
		Integer REVENUE_MONTHS = 12;
		Integer LINE_ITEM_CHUNK = 4;
		Set<Id> opportunityLineItemSet = new Set<Id>();
		Set<Id> budgetSet = new set<Id>();
		List<Product2> productCache = new List<Product2>();
		List<PricebookEntry> pricebookEntryCache = new List<PricebookEntry>();
		List<PricebookEntry> standardPricebookEntryCache = new List<PricebookEntry>();
		List<OpportunityLineItem> opportunityLineItemCache = new List<OpportunityLineItem>();
		List<Budget__c> budgetCache = new List<Budget__c>();
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
		for (i = 0; i < 24; i++)
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
				UnitPrice = pricebookEntryCache.get(i == 3 ? i - 1 : i).UnitPrice,
				Quantity = (i + 1),
				Revenue_Projection_Method__c = 'Straight Line',
				Revenue_Months__c = REVENUE_MONTHS,
				Revenue_Start_Date__c = Date.today().addYears(10),
				Pricing_Model__c = 'PEPM');
			opportunityLineItemCache.add(opportunityLineItem);
		}
		
		Test.startTest();
		insert opportunityLineItemCache;
		Test.stopTest();
		
		for (OpportunityLineItem opportunityLineItem : opportunityLineItemCache)
		{
			opportunityLineItemSet.add(opportunityLineItem.Id);
		}
		
		opportunityLineItemMap = new Map<Id, OpportunityLineItem>([
			SELECT
				Id,
				TotalPrice
			FROM
				OpportunityLineItem
			WHERE
				Id IN :opportunityLineItemSet]);
		
		List<Revenue_Schedule__c> testRevenueSchedules = new List<Revenue_Schedule__c>([
			SELECT
				Id,
				Opportunity_Line_Item_Id__c,
				Opportunity__c,
				Revenue_Amount__c,
				Revenue_Schedule_Date__c,
				Cumulative_Revenue__c,
				Budget__c,
				Previous_Revenue_Schedule__c
			FROM
				Revenue_Schedule__c
			WHERE
				Opportunity__c = :opportunity.Id
			ORDER BY
				Opportunity_Line_Item_Id__c]);
		System.assertEquals(LINE_ITEM_CHUNK * REVENUE_MONTHS, testRevenueSchedules.size());

		for (Revenue_Schedule__c testRevenueSchedule : testRevenueSchedules)
		{
			if (!testRevenueScheduleMap.containsKey(testRevenueSchedule.Opportunity_Line_Item_Id__c))
			{
				testRevenueScheduleMap.put(testRevenueSchedule.Opportunity_Line_Item_Id__c, new List<Revenue_Schedule__c>());
			}
			testRevenueScheduleMap.get(testRevenueSchedule.Opportunity_Line_Item_Id__c).add(testRevenueSchedule);
		}
		
		for (String strValue : testRevenueScheduleMap.keySet())
		{
			Decimal dTotal = 0;
			for (Revenue_Schedule__c revenueSchedule : testRevenueScheduleMap.get(strValue))
			{
//				System.assertEquals(true, budgetSet.contains(revenueSchedule.Budget__c));
				dTotal += revenueSchedule.Revenue_Amount__c;
			}
			if (opportunityLineItemMap.containsKey((Id)strValue))
			{
				System.assertEquals(opportunityLineItemMap.get((Id)strValue).TotalPrice, dTotal);
			}
		}
		
		testRevenueSchedules = new List<Revenue_Schedule__c>([
			SELECT
				Id,
				Opportunity_Line_Item_Id__c,
				Opportunity__c,
				Revenue_Amount__c,
				Revenue_Schedule_Date__c,
				Cumulative_Revenue__c,
				Budget__c,
				Previous_Revenue_Schedule__c
			FROM
				Revenue_Schedule__c
			WHERE
				Opportunity_Line_Item_Id__c = :opportunityLineItemCache.get(0).Id]);
		System.assertEquals(REVENUE_MONTHS, testRevenueSchedules.size());
		
		Opportunity opportunity1 = new Opportunity(
			Name = 'Apex Test Opportunity',
			StageName = 'Closed Won',
			CloseDate = Date.today().addYears(10),
			AccountId = account.Id,
			Revenue_Type__c = '	New Business');
		insert opportunity1;
		System.assertNotEquals(opportunity1.Id, null);
		
		ApexPages.StandardController controller = new ApexPages.StandardController(opportunity1);
		GSP_SC_ctrScheduleEdit extension = new GSP_SC_ctrScheduleEdit(controller);
		
		
		opportunity1.StageName = 'Prospecting';
		update opportunity1;
		
		GSP_SC_TriggerContext.DisableOpportunityLineItemTriggers = false;
		
		controller = new ApexPages.StandardController(opportunity1);
		extension = new GSP_SC_ctrScheduleEdit(controller);
		
		controller = new ApexPages.StandardController(opportunity);
		extension = new GSP_SC_ctrScheduleEdit(controller);
		System.assertEquals(true, extension.hasDynamicFields);
		System.assertEquals(false, extension.dynamicFields.isEmpty());		
		
		System.assertEquals(LINE_ITEM_CHUNK, extension.opportunityLineItems.size());

		extension.opportunityLineItems.get(0).Revenue_Months__c += 1;
		System.assertEquals(null, extension.SaveLineItems());
	}    
}