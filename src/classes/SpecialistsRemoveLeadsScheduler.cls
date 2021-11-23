/**
 * Created by Pavel Kovalevsky on 2/3/2021.
 */
global class SpecialistsRemoveLeadsScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {

        Datetime checkDate = System.now().addSeconds(-3);
        Map<Id, Lead> leadsForDelete = new Map<Id, Lead>([
            SELECT Latitude, Longitude
            FROM Lead
            WHERE CreatedDate < :checkDate
            AND LastName = 'Test' AND Company = 'Test'
        ]);

        List<Specialist__c> specs = [
            SELECT Lead__c, Location__latitude__s, Location__longitude__s
            FROM Specialist__c
            WHERE Lead__c IN: leadsForDelete.keySet()
        ];

        for (Specialist__c spec : specs) {
            spec.Location__latitude__s = leadsForDelete.get(spec.Lead__c).Latitude;
            spec.Location__longitude__s = leadsForDelete.get(spec.Lead__c).Longitude;
        }

        update specs;
        delete leadsForDelete.values();
        
        List<CronTrigger> jobList = [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'RemoveLeads'];
        System.debug('---jobList ' + jobList );
        for(CronTrigger job: jobList) {
           System.abortJob(job.Id);
        }
    }


}