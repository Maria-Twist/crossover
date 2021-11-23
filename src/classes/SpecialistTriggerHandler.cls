/**
 * Created by Pavel Kovalevsky on 11/25/2020.
 */
public with sharing class SpecialistTriggerHandler {

    final List<Specialist__c> newRecords;
    final Map<Id, Specialist__c> oldRecords;

    public SpecialistTriggerHandler(List<Specialist__c> newRecords, Map<Id, Specialist__c> oldRecords) {
        this.newRecords = newRecords;
        this.oldRecords = oldRecords;
    }

    public void beforeInsert() {
        List<Specialist__c> filteredSpecialists = new List<Specialist__c>();
        for (Specialist__c s : newRecords) {
            if ((String.isNotBlank(s.Country__c) && String.isNotBlank(s.City__c) && String.isNotBlank(s.Street__c)) ||
                String.isNotBlank(s.Zip__c)) {
                filteredSpecialists.add(s);
            }
        }

        if (!filteredSpecialists.isEmpty()) {
            createLeads(filteredSpecialists);
        }
    }

    public void beforeUpdate() {
        List<Specialist__c> filteredSpecialists = new List<Specialist__c>();
        for (Specialist__c s : newRecords) {
            if ((String.isNotBlank(s.Country__c) && String.isNotBlank(s.City__c) && String.isNotBlank(s.Street__c)) ||
                String.isNotBlank(s.Zip__c)) {
                if (oldRecords.get(s.Id).Country__c != s.Country__c || oldRecords.get(s.Id).City__c != s.City__c ||
                    oldRecords.get(s.Id).Street__c != s.Street__c || oldRecords.get(s.Id).Zip__c != s.Zip__c)   {
                    filteredSpecialists.add(s);
                }
            }
        }

        if (!filteredSpecialists.isEmpty()) {
            createLeads(filteredSpecialists);
        }
    }

    public void createLeads(List<Specialist__c> specs) {
        Map<Id, Lead> leadsToInsert = new Map<Id, Lead>();
        for (Specialist__c sp : specs) {
            Lead l = new Lead(
                    LastName = 'Test',
                    Company = 'Test',
                    Country = sp.Country__c,
                    City = sp.City__c,
                    Street = sp.Street__c,
                    PostalCode = sp.Zip__c
            );
            leadsToInsert.put(sp.Id, l);
        }

        insert leadsToInsert.values();

        for (Specialist__c sp : specs) {
            sp.Lead__c = leadsToInsert.get(sp.Id).Id;
        }
        
        String hour = String.valueOf(System.now().hour());
        String min = String.valueOf(System.now().minute());
        String ss = String.valueOf(System.now().second() + 5);
        //parse to cron expression
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        SpecialistsRemoveLeadsScheduler s = new SpecialistsRemoveLeadsScheduler();
        System.schedule('RemoveLeads', nextFireTime, s);
    }
}