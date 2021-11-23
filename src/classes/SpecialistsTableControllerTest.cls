/**
 * Created by Pavel Kovalevsky on 11/12/2020.
 */
@isTest
private class SpecialistsTableControllerTest {

    private static Patient_Referral__c currentRecord;
    private static Specialist__c specialist;

    private static void init() {
        Id rtId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Patient').getRecordTypeId();

        Contact patient = new Contact(LastName = 'Test', MailingStreet = '235 Morse Rd', MailingCity = 'Portland', MailingPostalCode = '72206',
        MailingCountry = 'United States', MailingLatitude = 34.672, MailingLongitude = -92.2682, EMR__c = 'emr', RecordTypeId = rtId);
        insert patient;

        currentRecord = new Patient_Referral__c(Patient__c = patient.Id, Specialty__c = 'Audiology', Status_Detail__c = 'Pending');
        insert currentRecord;

        specialist = new Specialist__c(Name = 'Specialist', Specialty__c = 'Audiology', Country__c = 'United States', City__c = 'Portland',
            Street__c = '235 Morse Rd', Zip__c = '72206');
        insert specialist;

        Specialty__c specialty = new Specialty__c(Specialist__c = specialist.Id, Name = 'Specialty', Cost__c = 15, Quality_Score__c = '1', XO_Internal_Rating__c = '1',
            XO_Provider_Rating__c = '2');
        insert specialty;
    }

    @isTest static void test_getInitialInfo() {
        init();
        Test.startTest();
        System.assertEquals(SpecialistsTableController.getInitialInfo(currentRecord.Id).size(), 1);
        Test.stopTest();
    }

    @isTest static void test_getFilteredRecords() {
        init();
        Test.startTest();
        System.assertEquals(SpecialistsTableController.getFilteredRecords(currentRecord.Id, '72206', 'Portland', 'Audiology').size(), 1);
        Test.stopTest();
    }

    @isTest static void test_updatePatientReferral() {
        init();
        specialist.Name = 'UpdatedName';
        update specialist;

        Test.startTest();
        SpecialistsTableController.updatePatientReferral(currentRecord.Id, specialist.Id, 1, 2, 3, 4, null);
        Test.stopTest();

        List<Patient_Referral__c> checkRef = [SELECT XO_Internal_Rating__c FROM Patient_Referral__c];
        System.assertEquals(checkRef.get(0).XO_Internal_Rating__c, '3');
    }

}