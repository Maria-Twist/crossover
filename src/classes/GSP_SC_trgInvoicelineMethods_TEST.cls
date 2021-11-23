/* Copyright (C) Gary Smith Partnership - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Gary Smith Partnership <gary@garysmithpartnership.com>, 22 Jul 2020
 */
@isTest
private class GSP_SC_trgInvoicelineMethods_TEST
{
	@isTest
	private static void test_LinkInvoicelineBudgets_Account()
	{
		Integer PRODUCT_CHUNK = 3;
		String CLINIC_NAME = 'AMP Austin';
		Set<Id> budgetSet = new Set<Id>();
		Set<Id> invoiceLineSet = new Set<Id>();
		List<String> productCodeList = new List<String>{ '12345', '17226', '27366' };
		List<Budget__c> budgetCache = new List<Budget__c>();
		List<Product2> productCache = new List<Product2>();
		List<Invoice_Line__c> invoiceLineCache = new List<Invoice_Line__c>();
		List<PricebookEntry> pricebookEntryCache = new List<PricebookEntry>();
		List<PricebookEntry> standardPricebookEntryCache = new List<PricebookEntry>();
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
				ProductCode = productCodeList.get(i));
			productCache.add(product);
		}
		insert productCache;

		Account account = new Account(
			Name = 'Apex Test Account',
			RevId__c = 'testAccount');
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
		
		Clinic__c clinic = new Clinic__c(
			Name = 'Apex Test Clinic',
			Clinic__c = CLINIC_NAME);
		insert clinic;
		System.assertNotEquals(clinic.Id, null);
		
		Clinic_Budget__c clinicBudget = new Clinic_Budget__c(
			Clinic__c = clinic.Id,
			Budget_date__c = Date.today().addYears(10).toStartOfMonth());
		insert clinicBudget;
		System.assertNotEquals(clinicBudget.Id, null);
			
		
		for (Product2 product : productCache)
		{
			Invoice_Line__c invoiceLine = new Invoice_Line__c(
				RevId__c = account.RevId__c,
				Accounting_Period__c = Date.today().addYears(10),
				Amount__c = 12000,
				Salesforce_Product__c = product.productCode,
				Clinic__c = CLINIC_NAME);
			invoiceLineCache.add(invoiceLine);
		}
		insert invoiceLineCache;
		
		for (Invoice_Line__c invoiceLine : invoiceLineCache)
		{
			invoiceLineSet.add(invoiceLine.Id);
		}
		
		for (Invoice_Line__c testInvoiceLine : [
			SELECT
				Budget__c,
				RevId__c,
				Account__c,
				Accounting_Period__c,
				Clinic_Budget__c
			FROM
				Invoice_Line__c
			WHERE
				Id IN :invoiceLineSet])
		{
			System.assertEquals(true, budgetSet.contains(testInvoiceLine.Budget__c));
			System.assertNotEquals(null, testInvoiceLine.Clinic_Budget__c);
		}
	}
	
	@isTest
	private static void test_LinkInvoicelineBudgets_AccountName()
	{
		Integer PRODUCT_CHUNK = 3;
		String CLINIC_NAME = 'AMP Austin';
		Set<Id> budgetSet = new Set<Id>();
		Set<Id> invoiceLineSet = new Set<Id>();
		List<String> productCodeList = new List<String>{ '12345', '17226', '27366' };
		List<Budget__c> budgetCache = new List<Budget__c>();
		List<Product2> productCache = new List<Product2>();
		List<Invoice_Line__c> invoiceLineCache = new List<Invoice_Line__c>();
		List<PricebookEntry> pricebookEntryCache = new List<PricebookEntry>();
		List<PricebookEntry> standardPricebookEntryCache = new List<PricebookEntry>();
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
				ProductCode = productCodeList.get(i));
			productCache.add(product);
		}
		insert productCache;

		Account account = new Account(
			Name = 'Apex Test Account',
			RevId__c = 'testAccount');
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
		
		Clinic__c clinic = new Clinic__c(
			Name = 'Apex Test Clinic',
			Clinic__c = CLINIC_NAME);
		insert clinic;
		System.assertNotEquals(clinic.Id, null);
		
		Clinic_Budget__c clinicBudget = new Clinic_Budget__c(
			Clinic__c = clinic.Id,
			Budget_date__c = Date.today().addYears(10).toStartOfMonth());
		insert clinicBudget;
		System.assertNotEquals(clinicBudget.Id, null);
		
		for (Product2 product : productCache)
		{
			Invoice_Line__c invoiceLine = new Invoice_Line__c(
				Account_Name__c = account.Name,
				Accounting_Period__c = Date.today().addYears(10),
				Amount__c = 12000,
				Salesforce_Product__c = product.productCode,
				Clinic__c = CLINIC_NAME);
			invoiceLineCache.add(invoiceLine);
		}
		insert invoiceLineCache;
		
		for (Invoice_Line__c invoiceLine : invoiceLineCache)
		{
			invoiceLineSet.add(invoiceLine.Id);
		}
		
		for (Invoice_Line__c testInvoiceLine : [
			SELECT
				Budget__c,
				RevId__c,
				Account__c,
				Accounting_Period__c,
				Clinic_Budget__c
			FROM
				Invoice_Line__c
			WHERE
				Id IN :invoiceLineSet])
		{
			System.assertEquals(true, budgetSet.contains(testInvoiceLine.Budget__c));
			System.assertNotEquals(null, testInvoiceLine.Clinic_Budget__c);
		}
	}
	
	@isTest
	private static void test_LinkInvoicelineBudgets_Owner()
	{
		Integer PRODUCT_CHUNK = 3;
		Set<Id> budgetSet = new set<Id>();
		Set<Id> invoiceLineSet = new Set<Id>();
		List<String> productCodeList = new List<String>{ '12345', '17226', '27366' };
		List<Budget__c> budgetCache = new List<Budget__c>();
		List<Product2> productCache = new List<Product2>();
		List<Invoice_Line__c> invoiceLineCache = new List<Invoice_Line__c>();
		List<PricebookEntry> pricebookEntryCache = new List<PricebookEntry>();
		List<PricebookEntry> standardPricebookEntryCache = new List<PricebookEntry>();
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
				ProductCode = productCodeList.get(i));
			productCache.add(product);
		}
		insert productCache;

		Account account = new Account(
			Name = 'Apex Test Account',
			RevId__c = 'testAccount');
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
		
		for (Product2 product : productCache)
		{
			Invoice_Line__c invoiceLine = new Invoice_Line__c(
				RevId__c = account.RevId__c,
				Accounting_Period__c = Date.today().addYears(10),
				Amount__c = 12000,
				Salesforce_Product__c = product.productCode);
			invoiceLineCache.add(invoiceLine);
		}
		insert invoiceLineCache;
		
		for (Invoice_Line__c invoiceLine : invoiceLineCache)
		{
			invoiceLineSet.add(invoiceLine.Id);
		}
		
		for (Invoice_Line__c testInvoiceLine : [
			SELECT
				Budget__c,
				RevId__c,
				Account__c,
				Accounting_Period__c
			FROM
				Invoice_Line__c
			WHERE
				Id IN :invoiceLineSet])
		{
			System.assertEquals(true, budgetSet.contains(testInvoiceLine.Budget__c));
		}
	}
	
	@isTest
	private static void test_LinkInvoicelineBudgets_DateChange()
	{
		Integer PRODUCT_CHUNK = 3;
		Set<Id> budgetSet = new set<Id>();
		Set<Id> invoiceLineSet = new Set<Id>();
		Invoice_Line__c modifiedInvoiceLine = null;
		List<String> productCodeList = new List<String>{ '12345', '17226', '27366' };
		List<Budget__c> budgetCache = new List<Budget__c>();
		List<Product2> productCache = new List<Product2>();
		List<Invoice_Line__c> invoiceLineCache = new List<Invoice_Line__c>();
		List<PricebookEntry> pricebookEntryCache = new List<PricebookEntry>();
		List<PricebookEntry> standardPricebookEntryCache = new List<PricebookEntry>();
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
				ProductCode = productCodeList.get(i));
			productCache.add(product);
		}
		insert productCache;

		Account account = new Account(
			Name = 'Apex Test Account',
			RevId__c = 'testAccount');
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
		
		for (Product2 product : productCache)
		{
			Invoice_Line__c invoiceLine = new Invoice_Line__c(
				RevId__c = account.RevId__c,
				Accounting_Period__c = Date.today().addYears(10),
				Amount__c = 12000,
				Salesforce_Product__c = product.productCode);
			invoiceLineCache.add(invoiceLine);
		}
		insert invoiceLineCache;
		
		for (Invoice_Line__c invoiceLine : invoiceLineCache)
		{
			invoiceLineSet.add(invoiceLine.Id);
		}
		
		for (Invoice_Line__c testInvoiceLine : [
			SELECT
				Amount__c,
				Budget__c,
				Budget__r.Invoice_Total_Amount__c,
				RevId__c,
				Account__c,
				Accounting_Period__c
			FROM
				Invoice_Line__c
			WHERE
				Id IN :invoiceLineSet])
		{
			if (testInvoiceLine.Id == invoiceLineCache.get(0).Id)
			{
				modifiedInvoiceLine = testInvoiceLine;
			}
			System.assertEquals(true, budgetSet.contains(testInvoiceLine.Budget__c));
			System.assertEquals(testInvoiceLine.Amount__c, testInvoiceLine.Budget__r.Invoice_Total_Amount__c);
		}
		
		System.assertNotEquals(null, modifiedInvoiceLine);
		modifiedInvoiceLine.Accounting_Period__c = modifiedInvoiceLine.Accounting_Period__c.addMonths(1);
		update modifiedInvoiceLine;
		
		List<Invoice_Line__c> testInvoiceLines = new List<Invoice_Line__c>([
			SELECT
				Amount__c,
				Budget__c,
				Budget__r.Invoice_Total_Amount__c,
				RevId__c,
				Accounting_Period__c
			FROM
				Invoice_Line__c
			WHERE
				Id = :modifiedInvoiceLine.Id]);
		System.assertEquals(1, testInvoiceLines.size());
		Invoice_Line__c testInvoiceLine = testInvoiceLines.get(0);
		System.assertEquals(true, budgetSet.contains(testInvoiceLine.Budget__c));
		System.assertEquals(testInvoiceLine.Amount__c, testInvoiceLine.Budget__r.Invoice_Total_Amount__c);
		System.assertNotEquals(modifiedInvoiceLine.Budget__c, testInvoiceLine.Budget__c);
		
		List<Budget__c> testBudgets = new List<Budget__c>([
			SELECT
				Id,
				Invoice_Total_Amount__c
			FROM
				Budget__c
			WHERE
				Id = :modifiedInvoiceLine.Budget__c]);
		System.assertEquals(1, testBudgets.size());
		Budget__c testBudget = testBudgets.get(0);
		System.assertEquals(0, testBudget.Invoice_Total_Amount__c);
	}
	
	@isTest
	private static void test_LinkInvoicelineBudgets_AccountDelete()
	{
		Integer PRODUCT_CHUNK = 3;
		Set<Id> budgetSet = new set<Id>();
		Set<Id> invoiceLineSet = new Set<Id>();
		Invoice_Line__c modifiedInvoiceLine = null;
		List<String> productCodeList = new List<String>{ '12345', '17226', '27366' };
		List<Budget__c> budgetCache = new List<Budget__c>();
		List<Product2> productCache = new List<Product2>();
		List<Invoice_Line__c> invoiceLineCache = new List<Invoice_Line__c>();
		List<PricebookEntry> pricebookEntryCache = new List<PricebookEntry>();
		List<PricebookEntry> standardPricebookEntryCache = new List<PricebookEntry>();
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
				ProductCode = productCodeList.get(i));
			productCache.add(product);
		}
		insert productCache;

		Account account = new Account(
			Name = 'Apex Test Account',
			RevId__c = 'testAccount');
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
		
		for (Product2 product : productCache)
		{
			Invoice_Line__c invoiceLine = new Invoice_Line__c(
				RevId__c = account.RevId__c,
				Accounting_Period__c = Date.today().addYears(10),
				Amount__c = 12000,
				Salesforce_Product__c = product.productCode);
			invoiceLineCache.add(invoiceLine);
		}
		insert invoiceLineCache;
		
		for (Invoice_Line__c invoiceLine : invoiceLineCache)
		{
			invoiceLineSet.add(invoiceLine.Id);
		}
		
		budgetSet.clear();
		
		for (Invoice_Line__c testInvoiceLine : [
			SELECT
				Amount__c,
				Budget__c,
				Budget__r.Invoice_Total_Amount__c,
				RevId__c,
				Account__c,
				Accounting_Period__c
			FROM
				Invoice_Line__c
			WHERE
				Id IN :invoiceLineSet])
		{
			budgetSet.add(testInvoiceLine.Budget__c);
			System.assertEquals(true, budgetSet.contains(testInvoiceLine.Budget__c));
			System.assertEquals(testInvoiceLine.Amount__c, testInvoiceLine.Budget__r.Invoice_Total_Amount__c);
		}
		
		delete invoiceLineCache;

		for (Budget__c testBudget : [
			SELECT
				Id,
				Invoice_Total_Amount__c
			FROM
				Budget__c
			WHERE
				Id IN :budgetSet])
		{
			System.assertEquals(0, testBudget.Invoice_Total_Amount__c);
		}
	}
	
	@isTest
	private static void test_LinkInvoicelineProducts()
	{
		Integer PRODUCT_CHUNK = 3;
		List<String> productCodeList = new List<String>{ '12345', '17226', '27366' };
		List<Product2> productCache = new List<Product2>();
		List<PricebookEntry> pricebookEntryCache = new List<PricebookEntry>();
		List<PricebookEntry> standardPricebookEntryCache = new List<PricebookEntry>();
		List<Invoice_Line__c> invoiceLineCache = new List<Invoice_Line__c>();
		Map<String, Id> productCodeKeyedProductMap = new Map<String, Id>();
		Set<Id> invoiceLineSet = new Set<Id>();
		Pricebook2 pricebook, standardPricebook;
		Integer i, j;
		
		
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
		
		for (Product2 product : productCache)
		{
			productCodeKeyedProductMap.put(product.ProductCode, product.Id);
		}
		
		Account account = new Account(
			Name = 'Apex Test Account',
			RevId__c = 'testAccount');
		insert account;
		System.assertNotEquals(account.Id, null);
		
		for (Product2 product : productCache)
		{
			Invoice_Line__c invoiceLine = new Invoice_Line__c(
				RevId__c = account.RevId__c,
				Accounting_Period__c = Date.today().addYears(10),
				Amount__c = 12000,
				Salesforce_Product__c = product.productCode);
			invoiceLineCache.add(invoiceLine);
		}
		insert invoiceLineCache;
		
		for (Invoice_Line__c invoiceLine : invoiceLineCache)
		{
			invoiceLineSet.add(invoiceLine.Id);
		}
		
		for (Invoice_Line__c testInvoiceLine : [
			SELECT
				Id,
				Product__c,
				Salesforce_Product__c
			FROM
				Invoice_Line__c
			WHERE
				Id IN :invoiceLineSet])
		{
			System.assertEquals(productCodeKeyedProductMap.get(testInvoiceLine.Salesforce_Product__c), testInvoiceLine.Product__c);
		}
	}
}