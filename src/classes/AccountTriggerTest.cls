/***********************************
Touchpoint Solutions
author: Tyler Zika
link: http://www.touchpointcrm.com
email: support@touchpointcrm.com
version: 1.0
date: 11/17/16
description: Test class for the trigger named AccountTrigger
***********************************/
@isTest(seeAllData=false)
private class AccountTriggerTest {
    
    public static List<Account> customerAccountList;
    public static List<Account> officeAccountList;
    
    /** Beginning of code to test if a child record is created
	of RecordTypeId 'Office Location' when Account is created of type RecordType 'Customer' **/
	
    static testMethod void testOnlyTwoOfficeLocationRecordsShouldBeCreated() {

        // Get the token for Account sObject
        Schema.sObjectType t = Account.sObjectType;
        
        // Get all active Account RecordTypes that are available to the running user
        // and assign it to a map where you can access each RecordType Id by the 
        // DeveloperName of the RecordType.
        // Check out the 'Utility' apex class if you have question on the function below
        Map<String, Id> accountTypes = Utility.getRecordTypeMapForObjectGeneric(t);   
        
        // Create 3 Accounts, 2 of RecordType 'Customer'
        customerAccountList = new List<Account>
        {
            new Account(Name = 'Test Account1', 
                        BillingCity = 'Fountain Valley', 
                        BillingCountry = 'United States', 
                        BillingPostalCode = '92708', 
                        BillingState = 'California', 
                        BillingStreet = '1234 Main St', 
                        ShippingCity = 'Fountain Valley', 
                        ShippingCountry = 'United States', 
                        ShippingPostalCode = '92708', 
                        ShippingState = 'California', 
                        ShippingStreet = '1234 Main St', 
                        RecordTypeId = accountTypes.get('Customer')),
            new Account(Name = 'Test Account2', 
                        BillingCity = 'Fountain Valley', 
                        BillingCountry = 'United States', 
                        BillingPostalCode = '92708', 
                        BillingState = 'California', 
                        BillingStreet = '1234 Main St', 
                        ShippingCity = 'Fountain Valley', 
                        ShippingCountry = 'United States', 
                        ShippingPostalCode = '92708', 
                        ShippingState = 'California', 
                        ShippingStreet = '1234 Main St', 
                        RecordTypeId = accountTypes.get('Clinic')),
            new Account(Name = 'Test Account3', 
                        BillingCity = 'Fountain Valley', 
                        BillingCountry = 'United States', 
                        BillingPostalCode = '92708', 
                        BillingState = 'California', 
                        BillingStreet = '1234 Main St', 
                        ShippingCity = 'Fountain Valley', 
                        ShippingCountry = 'United States', 
                        ShippingPostalCode = '92708', 
                        ShippingState = 'California', 
                        ShippingStreet = '1234 Main St', 
                        RecordTypeId = accountTypes.get('Customer'))
        };
            
        insert customerAccountList;
        
        // Two Accounts should have been created of RecordType 'Office Location'
        // and the record name should have ' Office Location' added to it
        officeAccountList = [SELECT Name, RecordTypeId 
                             FROM Account
                             WHERE RecordTypeId = :accountTypes.get('Office_Location')
                            ];
        
        System.assertEquals(2, officeAccountList.size());
        System.assertEquals(customerAccountList[0].Name + ' Office Location', officeAccountList[0].Name);
        System.assertEquals(customerAccountList[2].Name + ' Office Location', officeAccountList[1].Name);
    }
    
    /** End of code to test if a child record is created
	of RecordTypeId 'Office Location' when Account is created of type RecordType 'Customer' **/

    @isTest
    static void testInsertionManyAccounts() {

        // Get the token for Account sObject
        Schema.sObjectType t = Account.sObjectType;
        
        // Get all active Account RecordTypes that are available to the running user
        // and assign it to a map where you can access each RecordType Id by the 
        // DeveloperName of the RecordType.
        // Check out the 'Utility' apex class if you have question on the function below
        Map<String, Id> accountTypes = Utility.getRecordTypeMapForObjectGeneric(t);   
        
        // Create 200 Accounts of RecordType 'Customer'
        List<Account> testCustomerAccountList = new List<Account>();

        for (Integer i = 0; i < 200; i++) {
            testCustomerAccountList.add(new Account(
                Name = 'Test Account' + i, 
                BillingCity = 'Fountain Valley', 
                BillingCountry = 'United States', 
                BillingPostalCode = '92' + (700 + i), 
                BillingState = 'California', 
                BillingStreet = '1234 Main St', 
                ShippingCity = 'Fountain Valley', 
                ShippingCountry = 'United States', 
                ShippingPostalCode = '92' + (700 + i), 
                ShippingState = 'California', 
                ShippingStreet = '1234 Main St', 
                RecordTypeId = accountTypes.get('Customer'))
            );
        }
                    
        insert testCustomerAccountList;
        
        // Two hundred Accounts should have been created of RecordType 'Office Location'
        officeAccountList = [SELECT Name, RecordTypeId 
                             FROM Account
                             WHERE RecordTypeId = :accountTypes.get('Office_Location')
                            ];
        
        System.assertEquals(200, officeAccountList.size());
    }
    
}