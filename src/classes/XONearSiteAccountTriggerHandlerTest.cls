@isTest
private class XONearSiteAccountTriggerHandlerTest {

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
            StageName = 'Closed Won',
            Clinic_Launch_Date__c = Date.today(),
            CloseDate = Date.today(),
			Revenue_Type__c = '	New Business'
        );System.debug('OPP: ' + oppo);
        insert oppo;
    }

    @isTest static void testCommitedLivesCalc_Success() {
        if (XONearSiteAccountTriggerHandler.nearSiteOppoTypeId == null) {
            return;
        }
        init();

        Test.startTest();

        insert new Account(
            Name = 'Test 1',
            Close_Date__c = Date.today(),
            Near_Site_Opportunity__c = oppo.Id,
            Probability__c = 100,
            Number_of_Lives__c = 5
        );

        insert new Account(
            Name = 'Test 2',
            Close_Date__c = Date.today(),
            Near_Site_Opportunity__c = oppo.Id,
            Probability__c = 100,
            Number_of_Lives__c = 10
        );

        insert new Account(
            Name = 'Test 3',
            Close_Date__c = Date.today(),
            Near_Site_Opportunity__c = oppo.Id,
            Probability__c = 99,
            Number_of_Lives__c = 15
        );

        Test.stopTest();

        System.assertEquals(15, Integer.valueOf([SELECT Committed_Lives__c FROM Opportunity LIMIT 1].Committed_Lives__c));
    }

 /*   @isTest static void testPotentialLivesCalc_Success() {
        if (XONearSiteAccountTriggerHandler.nearSiteOppoTypeId == null) {
            return;
        }
        init();

        Test.startTest();

        insert new Account(
            Name = 'Test 1',
            Close_Date__c = Date.today(),
            Near_Site_Opportunity__c = oppo.Id,
            Probability__c = 100,
            Number_of_Lives__c = 5
        );

        insert new Account(
            Name = 'Test 2',
            Close_Date__c = Date.today(),
            Near_Site_Opportunity__c = oppo.Id,
            Probability__c = 100,
            Number_of_Lives__c = 10
        );

        insert new Account(
            Name = 'Test 3',
            Close_Date__c = Date.today(),
            Near_Site_Opportunity__c = oppo.Id,
            Probability__c = 99,
            Number_of_Lives__c = 15
        );

        Test.stopTest();

        System.assertEquals(30, Integer.valueOf([SELECT Potential_Lives__c FROM Opportunity LIMIT 1].Potential_Lives__c));
    }

    @isTest static void testWeightedLivesCalc_Success() {
        if (XONearSiteAccountTriggerHandler.nearSiteOppoTypeId == null) {

            return;
        }
        init();

        Test.startTest();

        insert new Account(
            Name = 'Test 1',
            Close_Date__c = Date.today(),
            Near_Site_Opportunity__c = oppo.Id,
            Probability__c = 100,
            Number_of_Lives__c = 5
        );

        insert new Account(
            Name = 'Test 2',
            Close_Date__c = Date.today(),
            Near_Site_Opportunity__c = oppo.Id,
            Probability__c = 100,
            Number_of_Lives__c = 10
        );

        insert new Account(
            Name = 'Test 3',
            Close_Date__c = Date.today(),
            Near_Site_Opportunity__c = oppo.Id,
            Probability__c = 50,
            Number_of_Lives__c = 10
        );

        Test.stopTest();

        System.assertEquals(20, Integer.valueOf([SELECT Weighted_Number_of_Lives__c FROM Opportunity LIMIT 1].Weighted_Number_of_Lives__c));
    }
    
        @isTest static void testWeightedLivesCalc_Success2() {
        if (XONearSiteAccountTriggerHandler.nearSiteOppoTypeId == null) {

            return;
        }
        init();

        Test.startTest();

        insert new Account(
            Name = 'Test 1',
            Close_Date__c = Date.today(),
            Near_Site_Opportunity__c = oppo.Id,
            Probability__c = 100,
            Number_of_Lives__c = 5
        );

        insert new Account(
            Name = 'Test 2',
            Close_Date__c = Date.today(),
            Near_Site_Opportunity__c = oppo.Id,
            Probability__c = 100,
            Number_of_Lives__c = 10
        );

        insert new Account(
            Name = 'Test 3',
            Close_Date__c = Date.today(),
            Near_Site_Opportunity__c = oppo.Id,
            Probability__c = 50,
            Number_of_Lives__c = 10
        );

        Test.stopTest();

        System.assertEquals(20, Integer.valueOf([SELECT Weighted_Number_of_Lives__c FROM Opportunity LIMIT 1].Weighted_Number_of_Lives__c));
    }

    @isTest static void testCommitedLivesCalc_OnDeleteSuccess() {
        if (XONearSiteAccountTriggerHandler.nearSiteOppoTypeId == null) {

            return;
        }
        init();

        Test.startTest();

        insert new Account(
            Name = 'Test 1',
            Close_Date__c = Date.today(),
            Near_Site_Opportunity__c = oppo.Id,
            Probability__c = 100,
            Number_of_Lives__c = 5
        );

        insert new Account(
            Name = 'Test 2',
            Close_Date__c = Date.today(),
            Near_Site_Opportunity__c = oppo.Id,
            Probability__c = 100,
            Number_of_Lives__c = 5
        );

        insert new Account(
            Name = 'Test 3',
            Close_Date__c = Date.today(),
            Near_Site_Opportunity__c = oppo.Id,
            Probability__c = 100,
            Number_of_Lives__c = 5
        );

        System.assertEquals(4, [SELECT Id FROM Account].size(), 'Accounts created: ' + [SELECT Id FROM Account].size());
        System.assert(![SELECT Id FROM Account WHERE Probability__c = 100 LIMIT 1].isEmpty(), 'No 100% Accounts created!: ' + [SELECT Probability__c FROM Account]);

        delete [
            SELECT Id
            FROM Account
                WHERE Probability__c = 100
            LIMIT 1
        ];

        Test.stopTest();

        System.assertEquals(10, Integer.valueOf([SELECT Committed_Lives__c FROM Opportunity LIMIT 1].Committed_Lives__c));
    }*/

}