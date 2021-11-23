/***********************************
Touchpoint Solutions
author: Tyler Zika
link: http://www.touchpointcrm.com
email: support@touchpointcrm.com
version: 1.0
date: 11/17/16
description: A single trigger for Account Object
***********************************/
trigger AccountTrigger on Account (after insert) {
    // Get the token for Account sObject
    Schema.SObjectType t = Account.SObjectType;
    // Get all active Account RecordTypes that are available to the running user
    // and assign it to a map where you can access each RecordType Id by the
    // DeveloperName of the RecordType.
    // Check out the 'Utility' apex class if you have question on the function below
    Map<String, Id> accountTypes = Utility.getRecordTypeMapForObjectGeneric(t);

    Map<String, String> accRtMap = new Map<String, String> {
            accountTypes.get('Customer') => accountTypes.get('Office_Location'),
            accountTypes.get('Broker_Consultant') => accountTypes.get('Broker_Consultant_Office_Location'),
            accountTypes.get('Payer') => accountTypes.get('Payer_Office_Location')
    };
    
    // After an Account is created
    if (Trigger.isAfter && Trigger.isInsert) {
        
        /** Beginning of code to create child record when Account is of type RecordType 'Customer' **/
            // collect all children accounts to insert for one DML operation 
            List<Account> accountChildren = new List<Account>();
    
        	// Go through each Account record that was created
            for(Account acc : Trigger.new) {
                
                // If the Account record being created is of RecordType 'Customer', 'Broker_Consultant', 'Payer'
                // create a child account record of RecordType 'Office Location', 'Broker_Consultant_Office_Location', 'Payer_Office_Location'
                // append ' Office Location' to the child record Name
                // copy the BillingAddress & ShippingAddress of the Account to the child Account
                // link parent with its child
                // insert into database
                if(accRtMap.containsKey(acc.RecordTypeId)) {
                    accountChildren.add(generateChildAccount(acc, accRtMap.get(acc.RecordTypeId)));
                }
            }

            if (!accountChildren.isEmpty()) {
                insert accountChildren;
            }
        
    	/** End of code to create child record when Account is of type 'Customer' **/
    }

    private static Account generateChildAccount(Account acc, String rtId) {
        Account accChild         	= new Account();
        accChild.RecordTypeId    	= rtId;
        accChild.Name            	= acc.Name + ' Office Location';

        accChild.BillingCity		= acc.BillingCity;
        accChild.BillingCountry		= acc.BillingCountry;
        accChild.BillingPostalCode	= acc.BillingPostalCode;
        accChild.BillingState		= acc.BillingState;
        accChild.BillingStreet		= acc.BillingStreet;

        accChild.ShippingCity		= acc.ShippingCity;
        accChild.ShippingCountry	= acc.ShippingCountry;
        accChild.ShippingPostalCode	= acc.ShippingPostalCode;
        accChild.ShippingState		= acc.ShippingState;
        accChild.ShippingStreet		= acc.ShippingStreet;

        accChild.ParentId           = acc.Id;

        return accChild;
    }

}