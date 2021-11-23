/***********************************
Touchpoint Solutions
author: Tyler Zika
link: http://www.touchpointcrm.com
email: support@touchpointcrm.com
version: 1.0
date: 11/17/16
description: a general class to keep code clean and reusable
***********************************/
public class Utility {
    
    
    /** Beginning of code to Obtain ALL Active Record Types, returning 
	a map of the IDs that each can be access using the DeveloperName of the Record Type*/
    
    //	This code is tested in the 'AccountTriggerTest' class
   
        //Record types cache
        private static Map<Schema.SObjectType,Map<String,Id>> rtypesCache;
        private static List<sObject> results;
        static {
            rtypesCache = new Map<Schema.SObjectType,Map<String,Id>>();//convenient map, formatted from results.
            results = new List<sObject>();//contains all recordtypes retrieved via SOQL
        }
        
        // Returns a map of active, user-available RecordType IDs for a given SObjectType,
        // keyed by each RecordType's unique, unchanging DeveloperName 
        public static Map<String, Id> getRecordTypeMapForObjectGeneric(Schema.SObjectType token) {
            // Do we already have a result? 
            Map<String, Id> mapRecordTypes = rtypesCache.get(token);
            // If not, build a map of RecordTypeIds keyed by DeveloperName
            if (mapRecordTypes == null) {
                mapRecordTypes = new Map<String, Id>();
                rtypesCache.put(token,mapRecordTypes);
            } else {
               // If we do, return our cached result immediately!
               return mapRecordTypes;
            }
        
            // Get the Describe Result
            Schema.DescribeSObjectResult obj = token.getDescribe();
        
        
            //Check if we already queried all recordtypes.
            if (results == null || results.isEmpty()) {
            // Obtain ALL Active Record Types
            // (We will filter out the Record Types that are unavailable
            // to the Running User using Schema information)
                String soql = 'SELECT Id, Name, DeveloperName, sObjectType FROM RecordType WHERE IsActive = TRUE';
                try {
                    results = Database.query(soql);
                } catch (Exception ex) {
                    results = new List<SObject>();
                }
            }
        
            // Obtain the RecordTypeInfos for this SObjectType token
            Map<Id,Schema.RecordTypeInfo> recordTypeInfos = obj.getRecordTypeInfosByID();
            // Loop through all of the Record Types we found,
            // and weed out those that are unavailable to the Running User
            for (SObject rt : results) { 
                if (recordTypeInfos.get(rt.Id) != null) {
                    if (recordTypeInfos.get(rt.Id).isAvailable()) {
                        // This RecordType IS available to the running user,
                        //      so add it to our map of RecordTypeIds by DeveloperName
                        mapRecordTypes.put(String.valueOf(rt.get('DeveloperName')),rt.Id);
                    }
                    else {
                        System.debug('The record type ' + rt.get('DeveloperName') + ' for object ' + rt.get('sObjectType') + ' is not availiable for the user.');
                    }
                }
            }
            
            return mapRecordTypes;
        }
    
    /** End of code to Obtain ALL Active Record Types, returning 
	a map of the IDs that each can be access using the DeveloperName of the RecordType*/

}