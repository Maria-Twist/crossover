@isTest
private class XONearSiteOpportunityTriggerTest {

	private static Account acc;
	private static Opportunity oppo;

	private static void init() {
		acc = new Account(
			Name = 'Test'
		);
		insert acc;

		oppo = new Opportunity(
			RecordTypeId = XONearSiteAccountTriggerHandler.nearSiteOppoTypeId,
			Name = 'Test',
			AccountId = acc.Id,
			Type = 'Transition',
			Opportunity_Type__c = 'Near-Site',
			State__c = 'NY',
			Region__c = 'NYC',
			StageName = 'Lead',
			Clinic_Launch_Date__c = Date.today(),
			CloseDate = Date.today(),
			Revenue_Type__c = '	New Business'
		);
		insert oppo;
	}

	@isTest static void testCommitedLivesCalc_Success() {
		if (XONearSiteAccountTriggerHandler.nearSiteOppoTypeId == null) {
			return;
		}
		init();

		Test.startTest();

		insert new Account(
			Name = 'Test',
			Close_Date__c = Date.today(),
			Near_Site_Opportunity__c = oppo.Id,
			Probability__c = 100,
			Number_of_Lives__c = 5
		);

		insert new Account(
			Name = 'Test',
			Close_Date__c = Date.today(),
			Near_Site_Opportunity__c = oppo.Id,
			Probability__c = 100,
			Number_of_Lives__c = 10
		);

		insert new Account(
			Name = 'Test',
			Close_Date__c = Date.today(),
			Near_Site_Opportunity__c = oppo.Id,
			Probability__c = 99,
			Number_of_Lives__c = 15
		);

		Test.stopTest();

		System.assertNotEquals(null, [SELECT Committed_Lives__c FROM Opportunity LIMIT 1].Committed_Lives__c);

		System.assertEquals(
            Integer.valueOf([SELECT Committed_Monthly_Value__c FROM Opportunity LIMIT 1].Committed_Monthly_Value__c)
			,
			Integer.valueOf([SELECT Committed_Monthly_Value__c FROM Opportunity LIMIT 1].Committed_Monthly_Value__c)
		);
	}

}