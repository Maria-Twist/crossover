/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, June, 2020
 */
@isTest
private class GSP_SC_trgOportunityLineItemMethod_TEST
{
	@isTest(seeAllData=true)
	private static void test_CreateSchedulesCurve()
	{
		List<Decimal> valueList = new List<Decimal>{  0.091188197000000, 0.011372911000000, 0.012789694000000,
			0.014382539000000, 0.016173212000000, 0.018186137000000, 0.020448714000000, 0.022991676000000, 0.025849476000000,
			0.029060722000000, 0.032668659000000, 0.036721702000000, 0.041274015000000, 0.046386157000000, 0.052125785000000,
			0.058568417000000, 0.065798264000000, 0.073909125000000, 0.083005345000000, 0.104630146000000, 0.117429573000000,
			0.131758301000000, 0.147789534000000, 0.165713607000000, 0.185739007000000, 0.208093275000000, 0.233023693000000,
			0.260797684000000, 0.291702793000000, 0.326046131000000, 0.364153091000000, 0.406365167000000, 0.453036626000000,
			0.504529787000000, 0.561208621000000, 0.623430367000000, 0.691534874000000, 0.765831369000000, 0.846582431000000,
			0.933985020000000, 1.028148574000000, 1.129070388000000, 1.236608761000000, 1.350454776000000, 1.470103973000000,
			0.093202836000000, 1.594829670000000, 1.723660143000000, 1.855362314000000, 1.988434901000000, 2.121114045000000,
			2.251394196000000, 2.377066400000000, 2.495775000000000, 2.605092288000000, 2.702608671000000, 2.786034054000000,
			2.853304077000000, 2.902683553000000, 2.932858680000000, 2.943009907000000, 2.932858680000000, 2.902683553000000,
			2.853304077000000, 2.786034054000000, 2.702608671000000, 2.605092288000000, 2.495775002000000, 2.377066400000000,
			2.251394196000000, 2.121114045000000, 1.988434901000000, 1.855362314000000, 1.723660143000000, 1.594829670000000,
			1.470103973000000, 1.350454776000000, 1.236608761000000, 1.129070388000000, 1.028148574000000, 0.933985020000000,
			0.846582431000000, 0.765831369000000, 0.691534874000000, 0.623430367000000, 0.561208621000000, 0.504529787000000,
			0.453036626000000, 0.406365167000000, 0.364153091000000, 0.326046131000000, 0.291702793000000, 0.260797684000000,
			0.233023693000000, 0.208093275000000, 0.185739007000000, 0.165713607000000, 0.147789534000000, 0.131758301000000,
			0.117429573000000, 0.104630146000000, 0.093202836000000, 0.083005345000000, 0.073909125000000, 0.065798264000000,
			0.058568417000000, 0.052125785000000, 0.046386157000000, 0.041274015000000, 0.036721702000000, 0.032668659000000,
			0.029060722000000, 0.025849476000000, 0.022991676000000, 0.020448714000000, 0.018186137000000, 0.016173212000000,
			0.014382539000000, 0.012789694000000, 0.011372911000000 };
			
		Integer PRODUCT_CHUNK = 3,
			REVENUE_MONTHS = 12,
			LINE_ITEM_CHUNK = 4;
			
		Set<Id> opportunityLineItemSet = new Set<Id>();
		Set<Id> budgetSet = new set<Id>();
		List<Product2> productCache = new List<Product2>();
		List<PricebookEntry> pricebookEntryCache = new List<PricebookEntry>();
		List<PricebookEntry> standardPricebookEntryCache = new List<PricebookEntry>();
		List<OpportunityLineItem> opportunityLineItemCache = new List<OpportunityLineItem>();
		List<Budget__c> budgetCache = new List<Budget__c>();
		List<Revenue_Schedule_Template_Line_Item__c> revenueScheduleTemplateLineItemCache = new List<Revenue_Schedule_Template_Line_Item__c>(); 
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

		List<Revenue_Schedule_Template__c> revenueScheduleTemplates = new List<Revenue_Schedule_Template__c>([
			SELECT
				Id,
				Type__c, (
				SELECT
					Id
				FROM
					Revenue_Schedule_Template_Line_Items__r)
			FROM
				Revenue_Schedule_Template__c]);
		if (revenueScheduleTemplates.isEmpty())
		{
			Revenue_Schedule_Template__c revenueScheduleTemplate = new Revenue_Schedule_Template__c(
				Name = 'S-Curve',
				Type__c = 'S-Curve',
				Duration_Months__c = valueList.size());
			insert revenueScheduleTemplate;
			System.assertNotEquals(revenueScheduleTemplate.Id, null);
			
			i = 1;
			Decimal dCumulativeTotal = 0;
			for (Decimal dValue : valueList)
			{
				dCumulativeTotal += dValue;
				Revenue_Schedule_Template_Line_Item__c revenueScheduleTemplateLineItem = new Revenue_Schedule_Template_Line_Item__c(
					Value_This_Month__c = dValue,
					Revenue_Schedule_Template__c = revenueScheduleTemplate.Id,
					Name = String.valueOf(i),
					Month__c = i++,
					Cumulative_Value__c = dCumulativeTotal);
				revenueScheduleTemplateLineItemCache.add(revenueScheduleTemplateLineItem);
			}
			insert revenueScheduleTemplateLineItemCache;
			
			for (i = 1; i < revenueScheduleTemplateLineItemCache.size(); i++)
			{
				revenueScheduleTemplateLineItemCache.get(i).Previous_Month_Line_Item__c = revenueScheduleTemplateLineItemCache.get(i - 1).Id;
			}
			update revenueScheduleTemplateLineItemCache;
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
				UnitPrice = pricebookEntryCache.get(i == 3 ? i - 1 : i).UnitPrice,
				Quantity = (i + 1),
				Revenue_Projection_Method__c = 'S-Curve',
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
	}
	
	@isTest(seeAllData=true)
	private static void test_CreateSchedulesLine()
	{
		Integer PRODUCT_CHUNK = 3;
		Integer REVENUE_MONTHS = 12;
		Integer LINE_ITEM_CHUNK = 4;
		String CLINIC_NAME = 'AMP Austin';
		Set<Id> opportunityLineItemSet = new Set<Id>();
		Set<Id> budgetSet = new set<Id>();
		List<Product2> productCache = new List<Product2>();
		List<PricebookEntry> pricebookEntryCache = new List<PricebookEntry>();
		List<PricebookEntry> standardPricebookEntryCache = new List<PricebookEntry>();
		List<OpportunityLineItem> opportunityLineItemCache = new List<OpportunityLineItem>();
		List<Budget__c> budgetCache = new List<Budget__c>();
		List<Clinic_Budget__c> clinicBudgetCache = new List<Clinic_Budget__c>();
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
		
		Clinic__c clinic = new Clinic__c(
			Name = 'Apex Test Clinic',
			Clinic__c = CLINIC_NAME);
		insert clinic;
		System.assertNotEquals(clinic.Id, null);
		
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
			Clinic_Budget__c clinicBudget = new Clinic_Budget__c(
				Clinic__c = clinic.Id,
				Budget_Date__c = dtBudget.addMonths(i));
			clinicBudgetCache.add(clinicBudget);
		}
		insert budgetCache;
		insert clinicBudgetCache;
		
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
				Pricing_Model__c = 'PEPM',
				Clinic__c = CLINIC_NAME);
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
				Previous_Revenue_Schedule__c,
				Clinic_Budget__c
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
				System.assertNotEquals(null, revenueSchedule.Clinic_Budget__c);
//				System.assertEquals(true, budgetSet.contains(revenueSchedule.Budget__c));
				dTotal += revenueSchedule.Revenue_Amount__c;
			}
			if (opportunityLineItemMap.containsKey((Id)strValue))
			{
				System.assertEquals(opportunityLineItemMap.get((Id)strValue).TotalPrice, dTotal);
			}
		}
		opportunityLineItemCache.get(0).Clinic__c = 'Apple Cork';
		update opportunityLineItemCache.get(0);
	}
	
	@isTest(seeAllData=true)
	private static void test_CreateSchedulesProductOverride()
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
				IsActive = true,
				Schedule_Interval_Override__c = 'D7',
				Revenue_Schedule_Method__c = 'Straight Line',
				Default_Revenue_Schedule_Months__c = REVENUE_MONTHS);
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
				UnitPrice = pricebookEntryCache.get(i == 3 ? i - 1 : i).UnitPrice,
				Quantity = (i + 1),
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
	}
	
	@isTest(seeAllData=true)
	private static void test_UpdateSchedulesDiscount()
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
		Decimal dTotal = 0;
		
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
		
		Date dt = Date.today().addYears(10).toStartOfMonth();
		for (i = 0; i < 12; i++)
		{
			Budget__c budget = new Budget__c(
				Budget_Date__c = dt.addMonths(i),
				Account__c = account.Id);
			budgetCache.add(budget);
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
				Revenue_Start_Date__c = Date.today(),
				Discount = 0,
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
				Opportunity_Line_Item_Id__c = :opportunityLineItemCache.get(0).Id]);
		System.assertEquals(REVENUE_MONTHS, testRevenueSchedules.size());
		
		for (Revenue_Schedule__c testRevenueSchedule : testRevenueSchedules)
		{
			dTotal += testRevenueSchedule.Revenue_Amount__c;
		}
		System.assertEquals(opportunityLineItemMap.get(opportunityLineItemCache.get(0).Id).TotalPrice, dTotal);
		
		GSP_SC_TriggerContext.DisableOpportunityLineItemTriggers = false;
		opportunityLineItemCache.get(0).Discount = opportunityLineItemCache.get(0).Discount + 5;
		update opportunityLineItemCache.get(0);
		
		opportunityLineItemMap = new Map<Id, OpportunityLineItem>([
			SELECT
				Id,
				TotalPrice
			FROM
				OpportunityLineItem
			WHERE
				Id IN :opportunityLineItemSet]);
		dTotal = 0;
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
		
		for (Revenue_Schedule__c testRevenueSchedule : testRevenueSchedules)
		{
			dTotal += testRevenueSchedule.Revenue_Amount__c;
		}
		Integer scale = Schema.sObjectType.Revenue_Schedule__c.fields.Revenue_Amount__c.getScale();
		System.assertEquals(opportunityLineItemMap.get(opportunityLineItemCache.get(0).Id).TotalPrice.setScale(scale), dTotal.setScale(scale));
	}
	
	@isTest(seeAllData=true)
	private static void test_UpdateSchedulesStartDate()
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
		Date dtScheduleStart = null;
		
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
		
		Date dt = Date.today().addYears(10).toStartOfMonth();
		for (i = 0; i < 12; i++)
		{
			Budget__c budget = new Budget__c(
				Budget_Date__c = dt.addMonths(i),
				Account__c = account.Id);
			budgetCache.add(budget);
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
				Revenue_Start_Date__c = Date.today(),
				Discount = 0,
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
				TotalPrice,
				Revenue_Start_Date__c
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
				Opportunity_Line_Item_Id__c = :opportunityLineItemCache.get(0).Id]);
		System.assertEquals(REVENUE_MONTHS, testRevenueSchedules.size());
		
		for (Revenue_Schedule__c testRevenueSchedule : testRevenueSchedules)
		{
			if (dtScheduleStart == null || dtScheduleStart > testRevenueSchedule.Revenue_Schedule_Date__c)
			{
				dtScheduleStart = testRevenueSchedule.Revenue_Schedule_Date__c;
			}
		}
		System.assertEquals(opportunityLineItemMap.get(opportunityLineItemCache.get(0).Id).Revenue_Start_Date__c, dtScheduleStart);

		GSP_SC_TriggerContext.DisableOpportunityLineItemTriggers = false;
		opportunityLineItemCache.get(0).Revenue_Start_Date__c = opportunityLineItemCache.get(0).Revenue_Start_Date__c.addMonths(2);
		update opportunityLineItemCache.get(0);
		
		opportunityLineItemMap = new Map<Id, OpportunityLineItem>([
			SELECT
				Id,
				TotalPrice,
				Revenue_Start_Date__c
			FROM
				OpportunityLineItem
			WHERE
				Id IN :opportunityLineItemSet]);
		dtScheduleStart = null;
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
		
		for (Revenue_Schedule__c testRevenueSchedule : testRevenueSchedules)
		{
			if (dtScheduleStart == null || dtScheduleStart > testRevenueSchedule.Revenue_Schedule_Date__c)
			{
				dtScheduleStart = testRevenueSchedule.Revenue_Schedule_Date__c;
			}
		}
		// Can't assert this because it depends on the number of days in the month
		//System.assertEquals(opportunityLineItemMap.get(opportunityLineItemCache.get(0).Id).Revenue_Start_Date__c, dtScheduleStart);
	}
	
	@isTest(seeAllData=true)
	private static void test_UpdateSchedulesScheduleCount()
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
		
		Date dt = Date.today().addYears(10).toStartOfMonth();
		for (i = 0; i < 24; i++)
		{
			Budget__c budget = new Budget__c(
				Budget_Date__c = dt.addMonths(i),
				Account__c = account.Id);
			budgetCache.add(budget);
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
				Revenue_Start_Date__c = Date.today(),
				Discount = 0,
				Pricing_Model__c = 'PEPM');
			opportunityLineItemCache.add(opportunityLineItem);
		}
		
		Test.startTest();
		insert opportunityLineItemCache;
		Test.stopTest();
		
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
				Opportunity_Line_Item_Id__c = :opportunityLineItemCache.get(0).Id]);
		System.assertEquals(REVENUE_MONTHS, testRevenueSchedules.size());
		GSP_SC_TriggerContext.DisableOpportunityLineItemTriggers = false;
		
		opportunityLineItemCache.get(0).Revenue_Months__c = opportunityLineItemCache.get(0).Revenue_Months__c + 2;
		update opportunityLineItemCache.get(0);

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
		System.assertEquals(REVENUE_MONTHS + 2, testRevenueSchedules.size());

		GSP_SC_TriggerContext.DisableOpportunityLineItemTriggers = false;
		opportunityLineItemCache.get(0).Revenue_Months__c = opportunityLineItemCache.get(0).Revenue_Months__c - 4;
		update opportunityLineItemCache.get(0);
		
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
		System.assertEquals(REVENUE_MONTHS - 2, testRevenueSchedules.size());
	}
	
	@isTest(seeAllData=true)
	private static void test_UpdateRevenueProjectionMethod()
	{
		List<Decimal> valueList = new List<Decimal>{  0.091188197000000, 0.011372911000000, 0.012789694000000,
			0.014382539000000, 0.016173212000000, 0.018186137000000, 0.020448714000000, 0.022991676000000, 0.025849476000000,
			0.029060722000000, 0.032668659000000, 0.036721702000000, 0.041274015000000, 0.046386157000000, 0.052125785000000,
			0.058568417000000, 0.065798264000000, 0.073909125000000, 0.083005345000000, 0.104630146000000, 0.117429573000000,
			0.131758301000000, 0.147789534000000, 0.165713607000000, 0.185739007000000, 0.208093275000000, 0.233023693000000,
			0.260797684000000, 0.291702793000000, 0.326046131000000, 0.364153091000000, 0.406365167000000, 0.453036626000000,
			0.504529787000000, 0.561208621000000, 0.623430367000000, 0.691534874000000, 0.765831369000000, 0.846582431000000,
			0.933985020000000, 1.028148574000000, 1.129070388000000, 1.236608761000000, 1.350454776000000, 1.470103973000000,
			0.093202836000000, 1.594829670000000, 1.723660143000000, 1.855362314000000, 1.988434901000000, 2.121114045000000,
			2.251394196000000, 2.377066400000000, 2.495775000000000, 2.605092288000000, 2.702608671000000, 2.786034054000000,
			2.853304077000000, 2.902683553000000, 2.932858680000000, 2.943009907000000, 2.932858680000000, 2.902683553000000,
			2.853304077000000, 2.786034054000000, 2.702608671000000, 2.605092288000000, 2.495775002000000, 2.377066400000000,
			2.251394196000000, 2.121114045000000, 1.988434901000000, 1.855362314000000, 1.723660143000000, 1.594829670000000,
			1.470103973000000, 1.350454776000000, 1.236608761000000, 1.129070388000000, 1.028148574000000, 0.933985020000000,
			0.846582431000000, 0.765831369000000, 0.691534874000000, 0.623430367000000, 0.561208621000000, 0.504529787000000,
			0.453036626000000, 0.406365167000000, 0.364153091000000, 0.326046131000000, 0.291702793000000, 0.260797684000000,
			0.233023693000000, 0.208093275000000, 0.185739007000000, 0.165713607000000, 0.147789534000000, 0.131758301000000,
			0.117429573000000, 0.104630146000000, 0.093202836000000, 0.083005345000000, 0.073909125000000, 0.065798264000000,
			0.058568417000000, 0.052125785000000, 0.046386157000000, 0.041274015000000, 0.036721702000000, 0.032668659000000,
			0.029060722000000, 0.025849476000000, 0.022991676000000, 0.020448714000000, 0.018186137000000, 0.016173212000000,
			0.014382539000000, 0.012789694000000, 0.011372911000000 };
			
		Integer PRODUCT_CHUNK = 3,
			REVENUE_MONTHS = 12,
			LINE_ITEM_CHUNK = 4,
			SCHEDULE_MONTHS = 120;
		Set<Id> opportunityLineItemSet = new Set<Id>();
		Set<Id> budgetSet = new set<Id>();
		List<Product2> productCache = new List<Product2>();
		List<PricebookEntry> pricebookEntryCache = new List<PricebookEntry>();
		List<PricebookEntry> standardPricebookEntryCache = new List<PricebookEntry>();
		List<OpportunityLineItem> opportunityLineItemCache = new List<OpportunityLineItem>();
		List<Budget__c> budgetCache = new List<Budget__c>();
		List<Revenue_Schedule_Template_Line_Item__c> revenueScheduleTemplateLineItemCache = new List<Revenue_Schedule_Template_Line_Item__c>(); 
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
		
		List<Revenue_Schedule_Template__c> revenueScheduleTemplates = new List<Revenue_Schedule_Template__c>([
			SELECT
				Id,
				Type__c, (
				SELECT
					Id
				FROM
					Revenue_Schedule_Template_Line_Items__r)
			FROM
				Revenue_Schedule_Template__c]);
		if (revenueScheduleTemplates.isEmpty())
		{
			Revenue_Schedule_Template__c revenueScheduleTemplate = new Revenue_Schedule_Template__c(
				Name = 'S-Curve',
				Type__c = 'S-Curve',
				Duration_Months__c = SCHEDULE_MONTHS);
			insert revenueScheduleTemplate;
			System.assertNotEquals(revenueScheduleTemplate.Id, null);
			
			i = 1;
			Decimal dCumulativeTotal = 0;
			for (Decimal dValue : valueList)
			{
				dCumulativeTotal += dValue;
				Revenue_Schedule_Template_Line_Item__c revenueScheduleTemplateLineItem = new Revenue_Schedule_Template_Line_Item__c(
					Value_This_Month__c = dValue,
					Revenue_Schedule_Template__c = revenueScheduleTemplate.Id,
					Name = String.valueOf(i),
					Month__c = i++,
					Cumulative_Value__c = dCumulativeTotal);
				revenueScheduleTemplateLineItemCache.add(revenueScheduleTemplateLineItem);
			}
			insert revenueScheduleTemplateLineItemCache;
			
			for (i = 1; i < revenueScheduleTemplateLineItemCache.size(); i++)
			{
				revenueScheduleTemplateLineItemCache.get(i).Previous_Month_Line_Item__c = revenueScheduleTemplateLineItemCache.get(i - 1).Id;
			}
			update revenueScheduleTemplateLineItemCache;
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
		
		Date dt = Date.today().addYears(10).toStartOfMonth();
		for (i = 0; i < 12; i++)
		{
			Budget__c budget = new Budget__c(
				Budget_Date__c = dt.addMonths(i),
				Account__c = account.Id);
			budgetCache.add(budget);
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
				Revenue_Start_Date__c = Date.today(),
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
				Previous_Revenue_Schedule__c,
				Revenue_Type__c
			FROM
				Revenue_Schedule__c
			WHERE
				Opportunity__c = :opportunity.Id
			ORDER BY
				Opportunity_Line_Item_Id__c]);
		System.assertEquals(LINE_ITEM_CHUNK * REVENUE_MONTHS, testRevenueSchedules.size());

		for (Revenue_Schedule__c testRevenueSchedule : testRevenueSchedules)
		{
			System.assertEquals('Straight Line', testRevenueSchedule.Revenue_Type__c);
		}

		GSP_SC_TriggerContext.DisableOpportunityLineItemTriggers = false;
		opportunityLineItemCache.get(0).Revenue_Projection_Method__c = 'S-Curve';
		update opportunityLineItemCache.get(0);
		
		testRevenueSchedules = new List<Revenue_Schedule__c>([
			SELECT
				Id,
				Opportunity_Line_Item_Id__c,
				Opportunity__c,
				Revenue_Amount__c,
				Revenue_Schedule_Date__c,
				Cumulative_Revenue__c,
				Budget__c,
				Previous_Revenue_Schedule__c,
				Revenue_Type__c
			FROM
				Revenue_Schedule__c
			WHERE
				Opportunity__c = :opportunity.Id
			ORDER BY
				Opportunity_Line_Item_Id__c]);
		System.assertEquals(LINE_ITEM_CHUNK * REVENUE_MONTHS, testRevenueSchedules.size());
		
		for (Revenue_Schedule__c testRevenueSchedule : testRevenueSchedules)
		{
			if (testRevenueSchedule.Opportunity_Line_Item_Id__c == opportunityLineItemCache.get(0).Id)
			{
				System.assertEquals('S-Curve', testRevenueSchedule.Revenue_Type__c);
			}
			else
			{
				System.assertEquals('Straight Line', testRevenueSchedule.Revenue_Type__c);
			}
		}
	}
	
	@isTest(seeAllData=true)
	private static void test_DeleteSchedules()
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
		
		Date dt = Date.today().addYears(10).toStartOfMonth();
		for (i = 0; i < 12; i++)
		{
			Budget__c budget = new Budget__c(
				Budget_Date__c = dt.addMonths(i),
				Account__c = account.Id);
			budgetCache.add(budget);
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
				Revenue_Start_Date__c = Date.today(),
				Pricing_Model__c = 'PEPM');
			opportunityLineItemCache.add(opportunityLineItem);
		}
		
		Test.startTest();
		insert opportunityLineItemCache;
		Test.stopTest();
		
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
		GSP_SC_TriggerContext.DisableOpportunityLineItemTriggers = false;
		delete opportunityLineItemCache;
		
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
		System.assertEquals(0, testRevenueSchedules.size());
	}
	
	@isTest(seeAllData=true)
	private static void test_CreateSchedulesLine_CatchAll()
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
		for (i = 0; i < 12; i++)
		{
			for (Product2 product : productCache)
			{
				Budget__c budget = new Budget__c(
					Budget_Date__c = dtBudget.addMonths(i),
					Account_Owner__c = userInfo.getUserId(),
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
	}
}