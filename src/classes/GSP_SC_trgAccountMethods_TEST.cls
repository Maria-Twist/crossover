/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, 21 Jul 2020
 */
 @isTest
private class GSP_SC_trgAccountMethods_TEST
{
	@isTest(seeAlldata=true)
	private static void test_UpdateScheduleAccountOwner()
	{
		Integer PRODUCT_CHUNK = 3;
		Integer REVENUE_MONTHS = 12;
		Integer LINE_ITEM_CHUNK = 4;
		Set<Id> opportunityLineItemSet = new Set<Id>();
		Set<Id> budgetSet = new Set<Id>(),
			budgetRunAsSet = new Set<Id>();
		List<String> productCodeList = new List<String>{ '12345', '17226', '27366' };
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
		
		List<Profile> profiles = new List<Profile>([
			SELECT
				Id
			FROM
				Profile
			WHERE
				Name = 'Standard User']);
		System.assertEquals(false, profiles.isEmpty());
		
		String userKey = EncodingUtil.ConvertTohex(Crypto.GenerateAESKey(128)).SubString(0,8);
      
		User user = new User(
			Alias = userKey,
			Email = userKey + '@testorg.com',
			EmailEncodingKey = 'UTF-8',
			LastName = 'Testing',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			ProfileId = profiles.get(0).Id,
			TimeZoneSidKey = 'America/Los_Angeles',
			UserName = userkey + '@testorg.com');
		insert user;
		System.assertNotEquals(user.Id, null);
		
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
				IsActive = true,
				ProductCode = productCodeList.get(i));
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
			Name = 'Apex Test Account',
			RevId__c = 'apex@test');
		insert account;
		System.assertNotEquals(account.Id, null);
		
		Date dt = Date.today().addYears(10).toStartOfMonth();
		for (i = 0; i < 12; i++)
		{
			for (Product2 product : productCache)
			{
				for (j = 0; j < 2; j++)
				{
					Budget__c budget = new Budget__c(
						Budget_Date__c = dt.addMonths(i),
						Account_Owner__c = j == 0 ? userInfo.getUserId() : user.Id,
						Product__c = product.Id);
					budgetCache.add(budget);
				}
			}
		}
		insert budgetCache;
		
		for (Budget__c budget : budgetCache)
		{
			if (budget.Account_Owner__c == userInfo.getUserId())
			{
				budgetSet.add(budget.Id);
			}
			else
			{
				budgetRunAsSet.add(budget.Id);
			}
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
		
		Invoice_Line__c invoiceLine = new Invoice_Line__c(
			RevId__c = account.RevId__c,
			Accounting_Period__c = Date.today().addYears(10),
			Salesforce_Product__c = productCache.get(0).ProductCode);
		insert invoiceLine;
		System.assertNotEquals(invoiceLine.Id, null);
		
		List<Invoice_line__c> testInvoiceLines = new List<Invoice_Line__c>([
			SELECT
				Id,
				Budget__c
			FROM
				Invoice_line__c
			WHERE
				Id = :invoiceLine.Id]);
		System.assertEquals(1, testInvoiceLines.size());
		Invoice_Line__c testInvoiceLine = testInvoiceLines.get(0);
		System.assertEquals(true, budgetSet.contains(testInvoiceLine.Budget__c));

		account.OwnerId = user.Id;
		update account;
		Test.stopTest();
		// Change Account Owner in the UI changes the Opportunity Owner
		// Change Account Owner in code DOES NOT change Opportunity Owner.
		// The below code asserts false
//		System.assertEquals(account.OwnerId, [SELECT OwnerId FROM Opportunity WHERE Id = :opportunity.Id].OwnerId);
		
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
				Opportunity__c = :opportunity.Id
			ORDER BY
				Opportunity_Line_Item_Id__c]);
		System.assertEquals(LINE_ITEM_CHUNK * REVENUE_MONTHS, testRevenueSchedules.size());

		for (Revenue_Schedule__c revenueSchedule : testRevenueSchedules)
		{
			System.assertEquals(true, budgetRunAsSet.contains(revenueSchedule.Budget__c));
		}
		
		testInvoiceLines = new List<Invoice_Line__c>([
			SELECT
				Id,
				Budget__c
			FROM
				Invoice_line__c
			WHERE
				Id = :invoiceLine.Id]);
		System.assertEquals(1, testInvoiceLines.size());
		testInvoiceLine = testInvoiceLines.get(0);
		System.assertEquals(true, budgetRunAsSet.contains(testInvoiceLine.Budget__c));
	}
}