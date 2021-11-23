@isTest
private class AddAccountsToNSOppControllerTest {
    
     static testMethod void validate() {
        
        //Insert your mock data here
        Opportunity newOpp = new Opportunity(
        	Name='test opp 1',
        	StageName='Lead',
        	CloseDate=Date.today(),
			Revenue_Type__c = '	New Business');
        insert newOpp;
         
        Account a = new Account(Name='test acc 1');
        insert a;
         
        a.Near_Site_Opportunity__c = newOpp.Id;
         
   

        //Construct your pagereference
        PageReference testPage = new pagereference('/apex/AddAccountsToNSOpp');
        testPage.getParameters().put('id', 'newOpp1.id');
        testPage.getParameters().put('accountName', '');
        Test.setCurrentPage(testPage);
        
         
        ApexPages.StandardController sc = new ApexPages.StandardController(newOpp);
        AddAccountsToNSOppController cont = new AddAccountsToNSOppController(sc);
         
        
         
        AddAccountsToNSOppController.aAccount innerCont = new AddAccountsToNSOppController.aAccount(a);
       	
		cont.accountList = null;
        cont.proccessSelected();
        cont.toggleSort();
        cont.runQuery();
        cont.runSearch();
       	
                
        
        System.assertEquals(newOpp.Id, a.Near_Site_Opportunity__c);
        System.assertEquals(newOpp.Id, cont.currentOppId);
         

         

      	
    }
}