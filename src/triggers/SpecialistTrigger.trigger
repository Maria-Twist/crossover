/**
 * Created by Pavel Kovalevsky on 11/25/2020.
 */
trigger SpecialistTrigger on Specialist__c (before insert, before update) {

    SpecialistTriggerHandler handler = new SpecialistTriggerHandler(Trigger.new, Trigger.oldMap);

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.beforeInsert();
        }
        if (Trigger.isUpdate) {
            handler.beforeUpdate();
        }
    }

}