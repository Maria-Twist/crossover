public with sharing class SearchProviderController {

    @AuraEnabled
    public static PatientObject getPatient(String recordId) {
        String objectName = String.valueOf(Id.valueOf(recordId).getSobjectType());
        PatientObject patient = new PatientObject();

        if (objectName == 'Patient_Referral__c') {
            recordId = [
                    SELECT Patient__c
                    FROM Patient_Referral__c
                    WHERE Id = :recordId
                    LIMIT 1
            ].Patient__c;

            if (String.isBlank(recordId)) {
                patient.error = 'Empty Patient in Patient Referral record.';
            } else {
                objectName = 'Contact';
            }
        }

        if (objectName == 'Contact') {
            Contact con = [
                    SELECT Id, Insurance__c
                    FROM Contact
                    WHERE Id = :recordId
                    LIMIT 1
            ];

            List<Castlight_Account__mdt> castlightIntegrations = getinsurancePlan(con.Insurance__c);

            if (castlightIntegrations.isEmpty()) {
                patient.error = 'The patient\'s plan was not found in the Castlight Reference. Provide this to your Salesforce Admin.';
            } else {
                patient.clientId = castlightIntegrations.get(0).Client_ID__c;
                patient.lumerisId = castlightIntegrations.get(0).GUID__c;
                patient.firstName = castlightIntegrations.get(0).First_Name__c;
                patient.lastName = castlightIntegrations.get(0).Last_Name__c;
                patient.insurance = con.Insurance__c;

                if (castlightIntegrations.get(0).DOB__c != null) {
                    patient.birthdate = String.valueOf(castlightIntegrations.get(0).DOB__c.year());
                    patient.birthdate += (String.valueOf(castlightIntegrations.get(0).DOB__c.month()).length() == 2) ? String.valueOf(castlightIntegrations.get(0).DOB__c.month()) : '0' + String.valueOf(castlightIntegrations.get(0).DOB__c.month());
                    patient.birthdate += (String.valueOf(castlightIntegrations.get(0).DOB__c.day()).length() == 2) ? String.valueOf(castlightIntegrations.get(0).DOB__c.day()) : '0' + String.valueOf(castlightIntegrations.get(0).DOB__c.day());
                }
            }
        } else if (objectName == 'Patient__c') {
            Patient__c pat = [
                    SELECT Id, Insurance__c
                    FROM Patient__c
                    WHERE Id = :recordId
                    LIMIT 1
            ];

            List<Castlight_Account__mdt> castlightIntegrations = getinsurancePlan(pat.Insurance__c);

            if (castlightIntegrations.isEmpty()) {
                patient.error = 'The patient\'s plan was not found in the Castlight Reference. Provide this to your Salesforce Admin.';
            } else {
                patient.clientId = castlightIntegrations.get(0).Client_ID__c;
                patient.lumerisId = castlightIntegrations.get(0).GUID__c;
                patient.firstName = castlightIntegrations.get(0).First_Name__c;
                patient.lastName = castlightIntegrations.get(0).Last_Name__c;
                patient.insurance = castlightIntegrations.get(0).Castlight_Plan__c;

                if (castlightIntegrations.get(0).DOB__c != null) {
                    patient.birthdate = String.valueOf(castlightIntegrations.get(0).DOB__c.year());
                    patient.birthdate += (String.valueOf(castlightIntegrations.get(0).DOB__c.month()).length() == 2) ? String.valueOf(castlightIntegrations.get(0).DOB__c.month()) : '0' + String.valueOf(castlightIntegrations.get(0).DOB__c.month());
                    patient.birthdate += (String.valueOf(castlightIntegrations.get(0).DOB__c.day()).length() == 2) ? String.valueOf(castlightIntegrations.get(0).DOB__c.day()) : '0' + String.valueOf(castlightIntegrations.get(0).DOB__c.day());
                }
            }
        }

        return patient;
    }

    private static List<Castlight_Account__mdt> getinsurancePlan(String insurance) {
        List<Castlight_Account__mdt> castling = [
                SELECT Plan__c, Client_ID__c, Castlight_Plan__c, DOB__c, First_Name__c, Last_Name__c, GUID__c
                FROM Castlight_Account__mdt
                WHERE Plan__c = :insurance
        ];

        return castling;
    }

    @AuraEnabled
    public static void savePatientInfo(String patientString) {
        Id userId = UserInfo.getUserId();

        PatientObject patient = (PatientObject)JSON.deserialize(patientString, PatientObject.class);

        User currentUser = new User(
                Id = userId,
                Castlight_Birthdate__c = patient.birthdate,
                Castlight_First_Name__c = patient.firstName,
                Castlight_Last_Name__c = patient.lastName,
                Castlight_Lumeris_Id__c = patient.lumerisId,
                Castlight_Client_Id__c = patient.clientId,
                FederationIdentifier = patient.insurance
        );

        update currentUser;
    }

    public class PatientObject {
        @AuraEnabled
        public String lumerisId;
        @AuraEnabled
        public String firstName;
        @AuraEnabled
        public String lastName;
        @AuraEnabled
        public String birthdate;
        @AuraEnabled
        public String insurance;
        @AuraEnabled
        public String clientId;
        @AuraEnabled
        public String error;
    }

}