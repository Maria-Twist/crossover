@IsTest
private class SearchProviderControllerTest {

    @IsTest
    static void testGetPatient() {
        Account acc = new Account(
                Name = 'Test'
        );
        insert acc;

        Contact con = new Contact(
                AccountId = acc.Id,
                LastName = 'Test',
                Insurance__c = 'Premera Health Savings Plan'
        );
        insert con;

        SearchProviderController.PatientObject patient = SearchProviderController.getPatient(con.Id);
        String patientString = JSON.serialize(patient);
        SearchProviderController.savePatientInfo(patientString);
    }

    @IsTest
    static void testGetPatientForPatient() {
        Patient__c pat = new Patient__c(
                Patient_First_Name__c = 'Test',
                Patient_Last_Name__c = 'Test',
                Insurance__c = 'Premera Health Savings Plan'
        );
        insert pat;

        SearchProviderController.PatientObject patient = SearchProviderController.getPatient(pat.Id);
        String patientString = JSON.serialize(patient);
        SearchProviderController.savePatientInfo(patientString);
    }
}